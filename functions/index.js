/**
 * Cloud Functions SAPA Alumni.
 *
 * Token Fonnte TIDAK BOLEH ada di aplikasi Flutter. Simpan sebagai secret:
 *   firebase functions:secrets:set FONNTE_TOKEN
 *
 * Deploy:
 *   cd functions && npm install && firebase deploy --only functions
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const FONNTE_TOKEN = defineSecret("FONNTE_TOKEN");
const REGION = "asia-southeast2";

/** Ubah 08xxx menjadi 628xxx. */
function normalizePhone(phone) {
  let digits = String(phone || "").replace(/[^0-9]/g, "");
  if (digits.startsWith("0")) digits = "62" + digits.slice(1);
  return digits;
}

/** Ambil role pemanggil dari koleksi users. */
async function getRole(uid) {
  const snap = await db.collection("users").doc(uid).get();
  return snap.exists ? snap.data().role : null;
}

/** Kirim notifikasi FCM ke satu user berdasarkan token tersimpan. */
async function pushToUser(userId, title, body, data = {}) {
  const userSnap = await db.collection("users").doc(userId).get();
  const token = userSnap.exists ? userSnap.data().fcmToken : null;
  if (!token) return;
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data,
    });
  } catch (err) {
    console.error("Gagal kirim FCM ke", userId, err.message);
  }
}

/* ------------------------------------------------------------------ */
/* 1. Kirim WhatsApp lewat Fonnte (dipanggil Admin/BKK dari Flutter)   */
/* ------------------------------------------------------------------ */
exports.sendWhatsapp = onCall(
  { region: REGION, secrets: [FONNTE_TOKEN] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Harus login.");

    const role = await getRole(uid);
    if (role !== "admin" && role !== "bkk") {
      throw new HttpsError("permission-denied", "Hanya admin atau BKK.");
    }

    const { targets, message, infoTitle } = request.data || {};
    if (!Array.isArray(targets) || targets.length === 0) {
      throw new HttpsError("invalid-argument", "Target penerima kosong.");
    }
    if (!message || String(message).trim() === "") {
      throw new HttpsError("invalid-argument", "Pesan tidak boleh kosong.");
    }

    const results = [];
    for (const target of targets) {
      const phone = normalizePhone(target.phone);
      if (phone.length < 10) {
        results.push({ phone: target.phone, ok: false, error: "Nomor tidak valid" });
        continue;
      }

      const text = String(message)
        .replace(/{nama}/g, target.name || "Alumni")
        .replace(/{judul_informasi}/g, infoTitle || "");

      try {
        const res = await fetch("https://api.fonnte.com/send", {
          method: "POST",
          headers: {
            "Authorization": FONNTE_TOKEN.value(),
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ target: phone, message: text }),
        });
        const json = await res.json();
        results.push({ phone, ok: res.ok && json.status !== false, detail: json });
      } catch (err) {
        results.push({ phone, ok: false, error: err.message });
      }
    }

    return {
      total: results.length,
      success: results.filter((r) => r.ok).length,
      results,
    };
  }
);

/* ------------------------------------------------------------------ */
/* 2. Notifikasi saat status lamaran berubah                          */
/* ------------------------------------------------------------------ */
exports.onApplicationStatusChanged = onDocumentUpdated(
  { region: REGION, document: "applications/{appId}" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after || before.status === after.status) return;

    const labels = {
      menunggu: "Menunggu",
      diproses: "Diproses",
      diterima: "Diterima",
      ditolak: "Ditolak",
    };
    const title = "Status lamaran diperbarui";
    const body = `Lamaran ${after.jobTitle || ""} kini berstatus ${labels[after.status] || after.status}.`;

    // Dokumen notifikasi in-app sudah dibuat aplikasi BKK,
    // di sini hanya mengirim push FCM.
    await pushToUser(after.alumniId, title, body, {
      type: "application",
      referenceId: event.params.appId,
    });
  }
);

/* ------------------------------------------------------------------ */
/* 3. Notifikasi broadcast untuk konten baru (topik "alumni")          */
/* ------------------------------------------------------------------ */
function broadcast(topic, title, body, type, referenceId) {
  return admin.messaging().send({
    topic,
    notification: { title, body },
    data: { type, referenceId },
  });
}

exports.onJobCreated = onDocumentCreated(
  { region: REGION, document: "jobs/{jobId}" },
  async (event) => {
    const job = event.data.data();
    if (!job) return;
    await broadcast("alumni", "Lowongan baru", `${job.title} di ${job.company}`, "job", event.params.jobId);
  }
);

exports.onScholarshipCreated = onDocumentCreated(
  { region: REGION, document: "scholarships/{id}" },
  async (event) => {
    const item = event.data.data();
    if (!item) return;
    await broadcast("alumni", "Informasi beasiswa baru", item.title, "scholarship", event.params.id);
  }
);

exports.onTrainingCreated = onDocumentCreated(
  { region: REGION, document: "trainings/{id}" },
  async (event) => {
    const item = event.data.data();
    if (!item) return;
    await broadcast("alumni", "Informasi pelatihan baru", item.title, "training", event.params.id);
  }
);

exports.onAnnouncementCreated = onDocumentCreated(
  { region: REGION, document: "announcements/{id}" },
  async (event) => {
    const item = event.data.data();
    if (!item) return;
    await broadcast("alumni", "Pengumuman baru", item.title, "announcement", event.params.id);
  }
);
