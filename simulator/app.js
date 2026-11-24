// State Management untuk Simulator
const mockInitialCards = [
  {
    id: "card-1",
    issuer: "bca",
    issuerName: "BCA Flazz",
    brandName: "Flazz",
    generation: "Gen 2",
    alias: "Flazz Harian Tol",
    maskedNum: "04A2 •••• •••• E6F7",
    balance: 137000,
    lastScanned: new Date(Date.now() - 3600 * 2000),
    transactions: [
      { id: 1, type: "Pembayaran Tol", merchant: "Gerbang Tol Cikarang Utama", amount: -14500, time: "Hari ini, 07:45" },
      { id: 2, type: "Minimarket", merchant: "Indomaret Point", amount: -45000, time: "Kemarin, 18:20" },
      { id: 3, type: "Transportasi", merchant: "TransJakarta Monas", amount: -3500, time: "2 hari lalu" },
      { id: 4, type: "Top Up Saldo", merchant: "ATM BCA / Mobile", amount: 100000, time: "3 hari lalu" }
    ]
  },
  {
    id: "card-2",
    issuer: "mandiri",
    issuerName: "Mandiri e-money",
    brandName: "e-money",
    generation: "v2.0",
    alias: "e-Money Tol Jagorawi",
    maskedNum: "045B •••• •••• C190",
    balance: 82500,
    lastScanned: new Date(Date.now() - 86400 * 1000),
    transactions: [
      { id: 1, type: "Pembayaran Tol", merchant: "Gerbang Kuningan", amount: -18000, time: "Kemarin, 09:15" },
      { id: 2, type: "Parkir", merchant: "Central Park Mall", amount: -12500, time: "2 hari lalu" }
    ]
  },
  {
    id: "card-3",
    issuer: "bni",
    issuerName: "BNI TapCash",
    brandName: "TapCash",
    generation: "Gen 2",
    alias: "TapCash MRT & Busway",
    maskedNum: "0411 •••• •••• 98AF",
    balance: 64500,
    lastScanned: new Date(Date.now() - 86400 * 3000),
    transactions: [
      { id: 1, type: "MRT Jakarta", merchant: "Stasiun Bundaran HI", amount: -14000, time: "3 hari lalu" }
    ]
  }
];

// Load / Save Local Storage
let savedCards = JSON.parse(localStorage.getItem("tapemoney_cards")) || mockInitialCards;
let scanHistory = JSON.parse(localStorage.getItem("tapemoney_history")) || [
  { id: "h1", cardAlias: "Flazz Harian Tol", issuer: "bca", balance: 137000, time: "Hari ini, 09:12", status: "success" },
  { id: "h2", cardAlias: "e-Money Tol Jagorawi", issuer: "mandiri", balance: 82500, time: "Kemarin, 14:30", status: "success" },
  { id: "h3", cardAlias: "TapCash MRT & Busway", issuer: "bni", balance: 64500, time: "3 hari lalu", status: "success" }
];

let activeTab = "home";
let currentSimulatedResult = null;

// Audio Chime Effect (Web Audio API)
function playBeep(type = "success") {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);

    if (type === "success") {
      osc.type = "sine";
      osc.frequency.setValueAtTime(659.25, ctx.currentTime); // E5
      osc.frequency.setValueAtTime(880, ctx.currentTime + 0.1); // A5
      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.35);
      osc.start();
      osc.stop(ctx.currentTime + 0.35);
    } else {
      osc.type = "square";
      osc.frequency.setValueAtTime(220, ctx.currentTime);
      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);
      osc.start();
      osc.stop(ctx.currentTime + 0.25);
    }
  } catch (e) {
    console.log("Audio API unavailable:", e);
  }
}

// Format Rupiah
function formatRupiah(amount) {
  if (amount === null || amount === undefined) return "Rp --";
  return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(amount);
}

// Update Clock
function updateClock() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  document.getElementById("currentTime").innerText = `${hours}:${minutes}`;
}
setInterval(updateClock, 1000);
updateClock();

// Switch Bottom Tabs
function switchTab(tabId) {
  activeTab = tabId;
  document.querySelectorAll(".tab-page").forEach(page => page.classList.remove("active"));
  document.querySelectorAll(".tab-item").forEach(item => item.classList.remove("active"));

  document.getElementById(`tab-${tabId}`).classList.add("active");
  document.getElementById(`nav-${tabId}`).classList.add("active");

  if (tabId === "cards") renderAllCards();
  if (tabId === "history") renderFullHistory("all");
}

// Render Dashboard
function renderDashboard() {
  const totalBalance = savedCards.reduce((acc, c) => acc + (c.balance || 0), 0);
  document.getElementById("metricCardCount").innerText = savedCards.length;
  document.getElementById("metricTotalBalance").innerText = formatRupiah(totalBalance);

  // Render recent card slider (first card)
  const slider = document.getElementById("recentCardsSlider");
  if (savedCards.length > 0) {
    const card = savedCards[0];
    slider.innerHTML = `
      <div class="card-visual ${card.issuer}">
        <div class="card-top">
          <div>
            <div class="card-brand-name">${card.brandName.toUpperCase()}</div>
            <div class="card-gen">${card.generation}</div>
          </div>
          <i class="fa-solid fa-wave-square card-nfc-wave"></i>
        </div>
        <div class="card-middle">
          <div class="emv-chip"></div>
          <div class="card-masked-num">${card.maskedNum}</div>
        </div>
        <div class="card-bottom">
          <div>
            <div class="card-alias-name">${card.alias}</div>
            <div class="card-scan-time">Baru saja discan</div>
          </div>
          <div class="card-balance-box">
            <span>Saldo</span>
            <strong>${formatRupiah(card.balance)}</strong>
          </div>
        </div>
      </div>
    `;
  } else {
    slider.innerHTML = `<div style="text-align:center; padding: 20px; background: #1c1c1e; border-radius: 16px; font-size: 12px; color: #8e8e93;">Belum ada kartu tersimpan. Klik Scan di atas.</div>`;
  }

  // Render recent scan items
  const scansContainer = document.getElementById("recentScansList");
  scansContainer.innerHTML = scanHistory.slice(0, 3).map(scan => `
    <div class="scan-item-row">
      <div class="scan-item-icon"><i class="fa-solid fa-credit-card"></i></div>
      <div class="scan-item-details">
        <strong>${scan.cardAlias}</strong>
        <span>${scan.time}</span>
      </div>
      <div class="scan-item-amount">
        <strong>${formatRupiah(scan.balance)}</strong>
        <span class="status-badge-mini">BERHASIL</span>
      </div>
    </div>
  `).join("");
}

// Render Cards Page
function renderAllCards() {
  const container = document.getElementById("allCardsListView");
  container.innerHTML = savedCards.map(card => `
    <div class="card-visual ${card.issuer}" style="margin-bottom: 12px;">
      <div class="card-top">
        <div>
          <div class="card-brand-name">${card.brandName.toUpperCase()}</div>
          <div class="card-gen">${card.generation}</div>
        </div>
        <i class="fa-solid fa-wave-square card-nfc-wave"></i>
      </div>
      <div class="card-middle">
        <div class="emv-chip"></div>
        <div class="card-masked-num">${card.maskedNum}</div>
      </div>
      <div class="card-bottom">
        <div>
          <div class="card-alias-name">${card.alias}</div>
          <div class="card-scan-time">Tersimpan offline</div>
        </div>
        <div class="card-balance-box">
          <span>Saldo</span>
          <strong>${formatRupiah(card.balance)}</strong>
        </div>
      </div>
    </div>
  `).join("");
}

// Render History
function renderFullHistory(filter = "all") {
  const container = document.getElementById("fullHistoryList");
  const filtered = filter === "all" ? scanHistory : scanHistory.filter(h => h.issuer === filter);

  if (filtered.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding: 30px; color:#8e8e93; font-size:13px;">Tidak ada riwayat scan untuk kategori ini.</div>`;
    return;
  }

  container.innerHTML = filtered.map(scan => `
    <div class="scan-item-row" style="cursor: pointer;" onclick="openReceiptForScan('${scan.id}')" title="Klik untuk cetak/bagikan struk transaksi">
      <div class="scan-item-icon"><i class="fa-solid fa-receipt"></i></div>
      <div class="scan-item-details">
        <strong>${scan.cardAlias}</strong>
        <span>${scan.time} • <span style="color:#0a84ff; font-weight:600;"><i class="fa-solid fa-share-nodes"></i> Cetak Struk</span></span>
      </div>
      <div class="scan-item-amount">
        <strong>${formatRupiah(scan.balance)}</strong>
        <span class="status-badge-mini">SUKSES</span>
      </div>
    </div>
  `).join("");
}

function filterHistory(type) {
  document.querySelectorAll("#historyFilters .pill").forEach(p => p.classList.remove("active"));
  event.target.classList.add("active");
  renderFullHistory(type);
}

// Modal Controls
function openScanModal() {
  document.getElementById("nfcModal").classList.add("active");
  document.getElementById("nfcStatusTitle").innerText = "Siap Memindai";
  document.getElementById("nfcStatusDesc").innerText = "Posisikan kartu e-money menempel kuat di bagian belakang atas iPhone Anda.";

  // Auto-tap pilot card Flazz after 2 seconds if user tapped hero
  setTimeout(() => {
    simulateCardTap("bca");
  }, 1200);
}

function closeScanModal() {
  document.getElementById("nfcModal").classList.remove("active");
}

function closeResultModal() {
  document.getElementById("resultModal").classList.remove("active");
  renderDashboard();
}

// Simulate Card Tap Trigger
function simulateCardTap(type) {
  const modal = document.getElementById("nfcModal");
  modal.classList.add("active");

  const title = document.getElementById("nfcStatusTitle");
  const desc = document.getElementById("nfcStatusDesc");

  title.innerText = "Kartu Terdeteksi";
  desc.innerText = "Chip terdeteksi via ISO 7816. Mengirim instruksi APDU...";

  setTimeout(() => {
    title.innerText = "Membaca Saldo & Record...";
    desc.innerText = "Memverifikasi integritas data...";
  }, 600);

  setTimeout(() => {
    modal.classList.remove("active");
    showCardResult(type);
  }, 1200);
}

// Show Card Read Result
function showCardResult(type) {
  playBeep("success");

  let cardData;
  if (type === "bca") {
    cardData = {
      issuer: "bca",
      brandName: "Flazz",
      gen: "Gen 2",
      masked: "04A2 •••• •••• E6F7",
      balance: 137000,
      balanceStatus: "Berhasil",
      historyStatus: "Berhasil (4 Record)",
      txs: [
        { type: "Pembayaran Tol", loc: "Gerbang Tol Cikarang Utama", amt: -14500, time: "Hari ini, 07:45" },
        { type: "Retail / Minimarket", loc: "Indomaret Point", amt: -45000, time: "Kemarin, 18:20" },
        { type: "Transportasi", loc: "TransJakarta Monas", amt: -3500, time: "2 hari lalu" },
        { type: "Top Up Saldo", loc: "ATM BCA / Mobile", amt: 100000, time: "3 hari lalu" }
      ]
    };
  } else if (type === "mandiri") {
    cardData = {
      issuer: "mandiri",
      brandName: "e-money",
      gen: "Versi 2.0",
      masked: "045B •••• •••• C190",
      balance: 82500,
      balanceStatus: "Berhasil",
      historyStatus: "Tidak Tersedia di Chip",
      txs: [
        { type: "Tol Dalam Kota", loc: "Gerbang Kuningan", amt: -18000, time: "Kemarin, 09:15" },
        { type: "Parkir", loc: "Mall Central Park", amt: -12500, time: "2 hari lalu" }
      ]
    };
  } else if (type === "bni") {
    cardData = {
      issuer: "bni",
      brandName: "TapCash",
      gen: "Gen 2",
      masked: "0411 •••• •••• 98AF",
      balance: 64500,
      balanceStatus: "Berhasil",
      historyStatus: "Sesuai Chip",
      txs: [
        { type: "MRT Jakarta", loc: "Stasiun Bundaran HI", amt: -14000, time: "Hari ini, 10:00" }
      ]
    };
  } else if (type === "bri") {
    cardData = {
      issuer: "bri",
      brandName: "BRIZZI",
      gen: "Gen 2",
      masked: "0489 •••• •••• 33D1",
      balance: 45000,
      balanceStatus: "Berhasil",
      historyStatus: "Sesuai Chip",
      txs: [
        { type: "Tol Jagorawi", loc: "Gerbang Cibubur", amt: -10500, time: "Kemarin" }
      ]
    };
  } else {
    // Unknown fallback
    cardData = {
      issuer: "unknown",
      brandName: "Kartu Tak Dikenal",
      gen: "Tag NFC",
      masked: "047F •••• •••• AA12",
      balance: null,
      balanceStatus: "Belum Didukung",
      historyStatus: "Tidak Tersedia",
      txs: []
    };
  }

  currentSimulatedResult = cardData;

  const resultBody = document.getElementById("resultModalBody");
  resultBody.innerHTML = `
    <div class="card-visual ${cardData.issuer}">
      <div class="card-top">
        <div>
          <div class="card-brand-name">${cardData.brandName.toUpperCase()}</div>
          <div class="card-gen">${cardData.gen}</div>
        </div>
        <i class="fa-solid fa-wave-square card-nfc-wave"></i>
      </div>
      <div class="card-middle">
        <div class="emv-chip"></div>
        <div class="card-masked-num">${cardData.masked}</div>
      </div>
      <div class="card-bottom">
        <div>
          <div class="card-alias-name" id="previewAlias">${cardData.brandName} Baru</div>
          <div class="card-scan-time">Baru saja dibaca</div>
        </div>
        <div class="card-balance-box">
          <span>Saldo</span>
          <strong>${formatRupiah(cardData.balance)}</strong>
        </div>
      </div>
    </div>

    <div class="balance-showcase">
      <div class="label">Saldo Terverifikasi</div>
      <div class="amount">${formatRupiah(cardData.balance)}</div>
      <div class="timestamp">Waktu Scan: Baru saja (Offline)</div>
    </div>

    <div class="status-pills-row">
      <span class="status-pill ${cardData.balance ? 'success' : 'unsupported'}">Saldo: ${cardData.balanceStatus}</span>
      <span class="status-pill ${cardData.txs.length > 0 ? 'success' : 'unsupported'}">Riwayat: ${cardData.historyStatus}</span>
    </div>

    <div class="input-alias-box">
      <label>Nama / Alias Kartu:</label>
      <input type="text" id="cardAliasInput" value="${cardData.brandName} Pribadi" oninput="document.getElementById('previewAlias').innerText = this.value">
    </div>

    <div class="card-transactions-list">
      <div class="tx-header">
        <span>Riwayat Pada Chip</span>
        <span class="text-blue">${cardData.txs.length} Record</span>
      </div>
      ${cardData.txs.length > 0 ? cardData.txs.map(t => `
        <div class="tx-row">
          <div class="tx-desc">
            <strong>${t.type}</strong>
            <span>${t.loc} • ${t.time}</span>
          </div>
          <div class="tx-nominal ${t.amt > 0 ? 'plus' : 'minus'}">
            ${t.amt > 0 ? '+' : ''}${formatRupiah(t.amt)}
          </div>
        </div>
      `).join("") : '<div style="font-size:11px; color:#8e8e93; text-align:center; padding:10px;">Tidak ada record transaksi pada chip ini.</div>'}
    </div>

    <button class="btn-save-card" id="btnSaveCard" onclick="saveSimulatedCard()">
      <i class="fa-solid fa-floppy-disk"></i> Simpan ke Kartu Saya
    </button>
  `;

  document.getElementById("resultModal").classList.add("active");
}

function saveSimulatedCard() {
  if (!currentSimulatedResult) return;
  const alias = document.getElementById("cardAliasInput").value || `${currentSimulatedResult.brandName} Pribadi`;

  const newCard = {
    id: "card-" + Date.now(),
    issuer: currentSimulatedResult.issuer,
    issuerName: currentSimulatedResult.brandName,
    brandName: currentSimulatedResult.brandName,
    generation: currentSimulatedResult.gen,
    alias: alias,
    maskedNum: currentSimulatedResult.masked,
    balance: currentSimulatedResult.balance,
    lastScanned: new Date(),
    transactions: currentSimulatedResult.txs
  };

  savedCards.unshift(newCard);
  localStorage.setItem("tapemoney_cards", JSON.stringify(savedCards));

  scanHistory.unshift({
    id: "h-" + Date.now(),
    cardAlias: alias,
    issuer: currentSimulatedResult.issuer,
    balance: currentSimulatedResult.balance,
    time: "Baru saja",
    status: "success"
  });
  localStorage.setItem("tapemoney_history", JSON.stringify(scanHistory));

  const btn = document.getElementById("btnSaveCard");
  btn.classList.add("saved");
  btn.innerHTML = `<i class="fa-solid fa-check"></i> Tersimpan!`;
  setTimeout(() => {
    closeResultModal();
  }, 600);
}

// Reset Data
function resetAllData() {
  if (confirm("Hapus seluruh profil kartu dan riwayat scan offline?")) {
    localStorage.removeItem("tapemoney_cards");
    localStorage.removeItem("tapemoney_history");
    savedCards = [];
    scanHistory = [];
    renderDashboard();
    renderAllCards();
    renderFullHistory("all");
    alert("Seluruh data lokal berhasil dibersihkan.");
  }
}

// Export CSV
function exportHistoryCSV() {
  let csv = "Waktu,Kartu,Penerbit,Saldo (IDR),Status\n";
  scanHistory.forEach(s => {
    csv += `"${s.time}","${s.cardAlias}","${s.issuer}","${s.balance}","${s.status}"\n`;
  });

  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `TAPEMONEY_Riwayat_${Date.now()}.csv`;
  a.click();
}

// ==========================================
// FITUR STRUK BELANJA TRANSAKSI (RECEIPT)
// ==========================================
let currentReceiptData = null;
let receiptMode = 'single'; // Default: 1 Transaksi Terpilih (Sesuai Permintaan)
let selectedTxIndex = 0;

// Buka Struk untuk Kartu/Scan tertentu saat diklik di list Riwayat
function openReceiptForScan(scanId) {
  const scan = scanHistory.find(s => s.id === scanId) || scanHistory[0];
  const matchedCard = savedCards.find(c => c.alias === scan?.cardAlias || c.issuer === scan?.issuer) || savedCards[0];

  const now = new Date();
  const printDateStr = now.toLocaleDateString("id-ID") + " " + now.toLocaleTimeString("id-ID", { hour: '2-digit', minute: '2-digit' });

  // Default transactions jika kartu belum memiliki transaksi
  let txList = matchedCard?.transactions && matchedCard.transactions.length > 0 ? matchedCard.transactions : [
    { type: "Pembayaran Tol", merchant: "Gerbang Kuningan", amount: -18000, time: "24/11/2026 09:15" },
    { type: "Parkir", merchant: "Central Park Mall", amount: -12500, time: "23/11/2026 14:30" }
  ];

  currentReceiptData = {
    cardAlias: matchedCard?.alias || scan?.cardAlias || "e-money Pribadi",
    brandName: matchedCard?.brandName || "e-Money",
    generation: matchedCard?.generation || "ISO 7816",
    maskedNum: matchedCard?.maskedNum || "045B •••• •••• C190",
    balance: matchedCard?.balance || scan?.balance || 82500,
    printTime: printDateStr,
    transactions: txList
  };

  selectedTxIndex = 0;

  // Isi dropdown pilihan transaksi tunggal
  const selectElem = document.getElementById("singleTxSelect");
  selectElem.innerHTML = txList.map((tx, idx) => {
    const amtStr = (tx.amount > 0 ? "+" : "-") + " " + formatRupiah(Math.abs(tx.amount));
    return `<option value="${idx}">${tx.type} • ${amtStr} (${tx.merchant || 'Transaksi'})</option>`;
  }).join("");

  setReceiptMode('single');
  document.getElementById("receiptModal").classList.add("active");
}

function openReceiptModal() {
  openReceiptForScan(scanHistory[0]?.id);
}

function closeReceiptModal() {
  document.getElementById("receiptModal").classList.remove("active");
}

function setReceiptMode(mode) {
  receiptMode = mode;
  const btnSingle = document.getElementById("btnModeSingle");
  const btnAll = document.getElementById("btnModeAll");
  const pickerWrapper = document.getElementById("singleTxPickerWrapper");
  const titleElem = document.getElementById("receiptModalTitle");

  if (mode === 'single') {
    btnSingle.classList.add("active");
    btnAll.classList.remove("active");
    pickerWrapper.style.display = "flex";
    if (titleElem) titleElem.innerText = "Struk 1 Transaksi Terpilih";
  } else {
    btnSingle.classList.remove("active");
    btnAll.classList.add("active");
    pickerWrapper.style.display = "none";
    if (titleElem) titleElem.innerText = "Struk Semua Transaksi";
  }

  renderCurrentReceipt();
}

function onSingleTxChange(val) {
  selectedTxIndex = parseInt(val) || 0;
  renderCurrentReceipt();
}

function renderCurrentReceipt() {
  if (!currentReceiptData) return;
  const isSingle = receiptMode === 'single';
  const txList = currentReceiptData.transactions || [];
  const singleTx = txList[selectedTxIndex] || txList[0] || { type: "Pembayaran", merchant: "Merchant", amount: -15000, time: "Baru saja" };

  // 1. Populate Info Table
  document.getElementById("receiptInfoTable").innerHTML = `
    <div class="receipt-info-row">
      <span>WAKTU CETAK</span>
      <span>${currentReceiptData.printTime}</span>
    </div>
    <div class="receipt-info-row">
      <span>KARTU</span>
      <span>${currentReceiptData.cardAlias.toUpperCase()}</span>
    </div>
    <div class="receipt-info-row">
      <span>JENIS CHIP</span>
      <span>${currentReceiptData.brandName.toUpperCase()} (${currentReceiptData.generation})</span>
    </div>
    <div class="receipt-info-row">
      <span>NO. KARTU</span>
      <span>${currentReceiptData.maskedNum}</span>
    </div>
    <div class="receipt-info-row">
      <span>STATUS CHIP</span>
      <span>TERVERIFIKASI (OK)</span>
    </div>
  `;

  // 2. Populate Transaction Area
  const txContainer = document.getElementById("receiptTxItems");
  const receiptTitleNode = document.querySelector(".receipt-store-sub");
  const receiptDescNode = document.querySelector(".receipt-store-desc");

  if (isSingle) {
    if (receiptTitleNode) receiptTitleNode.innerText = "BUKTI TRANSAKSI E-MONEY";
    if (receiptDescNode) receiptDescNode.innerText = "TRANSAKSI TUNGGAL • OFFLINE CHIP";

    const amtStr = (singleTx.amount > 0 ? "+" : "-") + " " + formatRupiah(Math.abs(singleTx.amount));
    txContainer.innerHTML = `
      <div style="background: #f7f7f8; border-radius: 6px; padding: 10px; margin: 4px 0;">
        <div style="font-size: 8px; color: #777; margin-bottom: 2px;">TANGGAL & JAM TRANSAKSI:</div>
        <div style="font-size: 11px; font-weight: 700; margin-bottom: 6px;">${singleTx.time || currentReceiptData.printTime}</div>
        
        <div style="font-size: 8px; color: #777; margin-bottom: 2px;">JENIS TRANSAKSI:</div>
        <div style="font-size: 12px; font-weight: 900; color: #111; margin-bottom: 6px;">${singleTx.type.toUpperCase()}</div>

        <div style="font-size: 8px; color: #777; margin-bottom: 2px;">LOKASI / TERMINAL:</div>
        <div style="font-size: 11px; font-weight: 700; color: #333; margin-bottom: 8px;">${(singleTx.merchant || 'Gerbang / Terminal').toUpperCase()}</div>

        <div style="border-top: 1px dashed #bbb; padding-top: 6px; display: flex; justify-content: space-between; align-items: center;">
          <span style="font-size: 11px; font-weight: 900;">JUMLAH:</span>
          <span style="font-size: 16px; font-weight: 900; color: #111;">${amtStr}</span>
        </div>
      </div>
    `;
  } else {
    if (receiptTitleNode) receiptTitleNode.innerText = "STRUK CATATAN TRANSAKSI E-MONEY";
    if (receiptDescNode) receiptDescNode.innerText = "OFFLINE CHIP READER • ISO 7816";

    if (txList.length === 0) {
      txContainer.innerHTML = `<div style="text-align:center; font-size:9px; color:#666; padding:8px;">TIDAK ADA RECORD DI CHIP</div>`;
    } else {
      txContainer.innerHTML = txList.map((tx, idx) => {
        const amtStr = (tx.amount > 0 ? "+" : "-") + " " + formatRupiah(Math.abs(tx.amount));
        const txTime = tx.time || ("Record #" + (idx + 1));
        return `
          <div class="receipt-tx-entry">
            <div class="receipt-tx-left">
              <div class="receipt-tx-time">${txTime}</div>
              <div class="receipt-tx-name">${tx.type.toUpperCase()}</div>
              <div class="receipt-tx-loc">${tx.merchant || '-'}</div>
            </div>
            <div class="receipt-tx-amt">${amtStr}</div>
          </div>
        `;
      }).join("");
    }
  }

  // 3. Populate Summary
  const summaryElem = document.getElementById("receiptSummaryTable");
  const barcodeText = document.querySelector(".receipt-barcode-text");

  if (isSingle) {
    if (barcodeText) barcodeText.innerText = "* BUKTI TRANSAKSI TUNGGAL OFFLINE *";
    summaryElem.innerHTML = `
      <div class="receipt-summary-row total-balance">
        <span>SISA SALDO KARTU</span>
        <span>${formatRupiah(currentReceiptData.balance)}</span>
      </div>
    `;
  } else {
    if (barcodeText) barcodeText.innerText = "* TAPEMONEY - STRUK OFFLINE *";
    const totalPengeluaran = txList
      .filter(t => t.amount < 0)
      .reduce((acc, t) => acc + Math.abs(t.amount), 0);

    summaryElem.innerHTML = `
      <div class="receipt-summary-row">
        <span>JML TRANSAKSI</span>
        <span>${txList.length} RECORD</span>
      </div>
      <div class="receipt-summary-row">
        <span>TTL PENGELUARAN</span>
        <span>${formatRupiah(totalPengeluaran)}</span>
      </div>
      <div class="receipt-summary-row total-balance">
        <span>SISA SALDO KARTU</span>
        <span>${formatRupiah(currentReceiptData.balance)}</span>
      </div>
    `;
  }
}

// Download Struk Belanja Belanja sebagai Gambar (PNG) via HTML5 Canvas
function downloadReceiptPNG() {
  if (!currentReceiptData) return;

  const isSingle = receiptMode === 'single';
  const txList = currentReceiptData.transactions || [];
  const singleTx = txList[selectedTxIndex] || txList[0] || { type: "Pembayaran", merchant: "Merchant", amount: -15000, time: "Baru saja" };

  const width = 640;
  const padding = 36;
  const height = isSingle ? 600 : (460 + (txList.length * 44));

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");

  // Background Paper
  ctx.fillStyle = "#ffffff";
  ctx.fillRect(0, 0, width, height);

  ctx.fillStyle = "#111111";
  ctx.textAlign = "center";

  // Header Toko
  ctx.font = "bold 32px 'JetBrains Mono', monospace";
  ctx.fillText("TAPEMONEY", width / 2, 54);

  ctx.font = "bold 15px 'JetBrains Mono', monospace";
  ctx.fillStyle = "#555555";
  ctx.fillText(isSingle ? "BUKTI TRANSAKSI E-MONEY" : "STRUK CATATAN TRANSAKSI E-MONEY", width / 2, 82);

  ctx.font = "13px 'JetBrains Mono', monospace";
  ctx.fillStyle = "#777777";
  ctx.fillText(isSingle ? "TRANSAKSI TUNGGAL • OFFLINE CHIP" : "OFFLINE CHIP READER • ISO 7816", width / 2, 104);

  // Divider
  ctx.fillStyle = "#888888";
  ctx.fillText("------------------------------------------------", width / 2, 126);

  // Info Block (Left & Right)
  ctx.font = "15px 'JetBrains Mono', monospace";
  let y = 154;
  const rows = [
    ["WAKTU CETAK", currentReceiptData.printTime],
    ["KARTU", currentReceiptData.cardAlias.toUpperCase()],
    ["JENIS CHIP", currentReceiptData.brandName.toUpperCase() + " (" + currentReceiptData.generation + ")"],
    ["NO. KARTU", currentReceiptData.maskedNum],
    ["STATUS CHIP", "TERVERIFIKASI (OK)"]
  ];

  rows.forEach(([k, v]) => {
    ctx.textAlign = "left";
    ctx.fillStyle = "#666666";
    ctx.fillText(k, padding, y);
    ctx.textAlign = "right";
    ctx.fillStyle = "#111111";
    ctx.font = "bold 15px 'JetBrains Mono', monospace";
    ctx.fillText(v, width - padding, y);
    ctx.font = "15px 'JetBrains Mono', monospace";
    y += 24;
  });

  // Divider
  ctx.textAlign = "center";
  ctx.fillStyle = "#888888";
  ctx.fillText("------------------------------------------------", width / 2, y + 8);
  y += 30;

  if (isSingle) {
    // Single Tx Details Box on Canvas
    ctx.fillStyle = "#f6f6f7";
    ctx.fillRect(padding - 8, y - 6, width - (padding * 2) + 16, 150);

    ctx.textAlign = "left";
    ctx.font = "12px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#666666";
    ctx.fillText("TANGGAL & JAM:", padding, y + 14);
    ctx.font = "bold 15px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#111111";
    ctx.fillText(singleTx.time || currentReceiptData.printTime, padding, y + 32);

    ctx.font = "12px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#666666";
    ctx.fillText("JENIS TRANSAKSI & LOKASI:", padding, y + 54);
    ctx.font = "bold 16px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#111111";
    ctx.fillText(singleTx.type.toUpperCase() + " (" + (singleTx.merchant || 'Terminal') + ")", padding, y + 74);

    ctx.font = "bold 16px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#333333";
    ctx.fillText("JUMLAH NOMINAL:", padding, y + 116);

    ctx.textAlign = "right";
    const amtStr = (singleTx.amount > 0 ? "+" : "-") + " " + formatRupiah(Math.abs(singleTx.amount));
    ctx.font = "bold 26px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#000000";
    ctx.fillText(amtStr, width - padding, y + 118);

    y += 166;
  } else {
    // All Tx header & loop
    ctx.textAlign = "left";
    ctx.font = "bold 15px 'JetBrains Mono', monospace";
    ctx.fillStyle = "#222222";
    ctx.fillText("TGL/JAM • TRANSAKSI", padding, y);
    ctx.textAlign = "right";
    ctx.fillText("NOMINAL", width - padding, y);
    y += 18;

    ctx.textAlign = "center";
    ctx.fillStyle = "#aaaaaa";
    ctx.fillText(". . . . . . . . . . . . . . . . . . . . . . . . .", width / 2, y);
    y += 26;

    txList.forEach(tx => {
      ctx.textAlign = "left";
      ctx.font = "12px 'JetBrains Mono', monospace";
      ctx.fillStyle = "#777777";
      ctx.fillText(tx.time || "Record", padding, y);

      ctx.font = "bold 15px 'JetBrains Mono', monospace";
      ctx.fillStyle = "#111111";
      ctx.fillText(tx.type.toUpperCase() + (tx.merchant ? ` (${tx.merchant})` : ""), padding, y + 18);

      ctx.textAlign = "right";
      const amtStr = (tx.amount > 0 ? "+" : "-") + " " + formatRupiah(Math.abs(tx.amount));
      ctx.font = "bold 16px 'JetBrains Mono', monospace";
      ctx.fillText(amtStr, width - padding, y + 14);

      y += 44;
    });
  }

  // Divider
  ctx.textAlign = "center";
  ctx.fillStyle = "#888888";
  ctx.fillText("------------------------------------------------", width / 2, y);
  y += 30;

  // Sisa Saldo Kartu
  ctx.textAlign = "left";
  ctx.font = "bold 18px 'JetBrains Mono', monospace";
  ctx.fillStyle = "#111111";
  ctx.fillText("SISA SALDO KARTU", padding, y);

  ctx.textAlign = "right";
  ctx.font = "bold 22px 'JetBrains Mono', monospace";
  ctx.fillText(formatRupiah(currentReceiptData.balance), width - padding, y);
  y += 36;

  // Barcode Footer
  ctx.textAlign = "center";
  ctx.fillStyle = "#888888";
  ctx.fillText("------------------------------------------------", width / 2, y);
  y += 24;

  ctx.fillStyle = "#111111";
  ctx.font = "bold 14px 'JetBrains Mono', monospace";
  ctx.fillText(isSingle ? "* BUKTI TRANSAKSI TUNGGAL OFFLINE *" : "* TAPEMONEY - STRUK RESMI OFFLINE *", width / 2, y);
  y += 20;

  ctx.font = "12px 'JetBrains Mono', monospace";
  ctx.fillStyle = "#777777";
  ctx.fillText("SIMPAN SEBAGAI BUKTI RIWAYAT CHIP", width / 2, y);

  // Trigger Download PNG
  const fileName = isSingle ? `Struk_1_Transaksi_TAPEMONEY_${Date.now()}.png` : `Struk_Semua_TAPEMONEY_${Date.now()}.png`;
  const link = document.createElement("a");
  link.download = fileName;
  link.href = canvas.toDataURL("image/png");
  link.click();
}

// Download PDF via Browser Print
function downloadReceiptPDF() {
  const receiptHTML = document.getElementById("thermalReceiptNode").outerHTML;
  const printWindow = window.open("", "_blank", "width=420,height=600");
  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Cetak Struk TAPEMONEY</title>
      <style>
        body { font-family: 'Courier New', monospace; background: #f0f0f0; margin: 0; padding: 20px; display: flex; justify-content: center; }
        .thermal-receipt { width: 320px; background: white; padding: 18px; border: 1px solid #ccc; }
        .receipt-jagged-top, .receipt-jagged-bottom { display: none; }
        .receipt-store-title { font-size: 20px; font-weight: bold; text-align: center; }
        .receipt-store-sub, .receipt-store-desc { text-align: center; font-size: 11px; }
        .receipt-divider-dashed { text-align: center; letter-spacing: 1px; margin: 6px 0; }
        .receipt-info-table { font-size: 11px; }
        .receipt-info-row { display: flex; justify-content: space-between; margin-bottom: 2px; }
        .receipt-tx-head { display: flex; justify-content: space-between; font-weight: bold; font-size: 11px; margin: 4px 0; }
        .receipt-tx-entry { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 11px; }
        .receipt-summary-table { font-size: 11px; }
        .receipt-summary-row { display: flex; justify-content: space-between; margin-bottom: 3px; }
        .receipt-summary-row.total-balance { font-size: 13px; font-weight: bold; margin-top: 6px; padding-top: 4px; border-top: 1px dashed #666; }
        .receipt-barcode-box { text-align: center; font-size: 10px; margin-top: 10px; }
        .receipt-barcode-lines { height: 26px; background: repeating-linear-gradient(90deg, #000 0, #000 2px, transparent 2px, transparent 4px); margin: 6px auto; width: 80%; }
        @media print {
          body { background: white; padding: 0; }
          .thermal-receipt { border: none; width: 100%; }
        }
      </style>
    </head>
    <body onload="window.print(); window.close();">
      ${receiptHTML}
    </body>
    </html>
  `);
  printWindow.document.close();
}

// Initial render
renderDashboard();
