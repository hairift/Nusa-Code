import { useEffect, useState } from 'react'

const github = 'https://github.com/hairift/Nusa-Code'

const nusaExample = `# Deret Fibonacci dalam Nusa
fungsi fibonacci(n) maka
    jika n < 2 maka
        kembalikan n
    akhir_jika
    kembalikan fibonacci(n - 1) + fibonacci(n - 2)
akhir_fungsi

untuk i dari 0 sampai 9 maka
    tulis(fibonacci(i))
akhir_untuk`

const buildCommand = `git clone https://github.com/hairift/Nusa-Code.git
cd Nusa-Code
cargo build --release
cargo run --release -- examples/halo.nusa`

function CopyButton({ value, label = 'Salin' }: { value: string; label?: string }) {
  const [copied, setCopied] = useState(false)

  async function copy() {
    try {
      await navigator.clipboard.writeText(value)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1800)
    } catch {
      setCopied(false)
    }
  }

  return (
    <button className="copy-button" type="button" onClick={copy} aria-live="polite">

      {copied ? 'Tersalin' : label}
    </button>
  )
}

function ArrowIcon() {
  return <span aria-hidden="true">↗</span>
}

const navItems = [
  { id: 'beranda', label: 'Beranda' },
  { id: 'dokumentasi', label: 'Dokumentasi' },
  { id: 'unduh', label: 'Unduh' },
  { id: 'ekosistem', label: 'Ekosistem' },
]

const features = [
  {
    number: '01',
    title: 'Bahasa yang akrab',
    text: 'Kata kunci Indonesia dan Inggris dipetakan ke semantik yang sama sehingga pembelajaran lokal dan kolaborasi internasional dapat berjalan berdampingan.',
    status: 'Aktif',
  },
  {
    number: '02',
    title: 'Blok yang eksplisit',
    text: 'akhir_jika, akhir_untuk, dan akhir_fungsi membuat batas struktur terlihat tanpa menggantungkan makna pada indentasi.',
    status: 'Aktif',
  },
  {
    number: '03',
    title: 'Runtime portabel',
    text: 'Interpreter referensi berbasis Rust menjalankan berkas .nusa pada Windows, Linux, dan macOS tanpa ketergantungan runtime eksternal.',
    status: 'Aktif',
  },
  {
    number: '04',
    title: 'Diagnostik yang jelas',
    text: 'Pesan kesalahan berbahasa Indonesia dirancang untuk membantu pembelajar memahami penyebab, bukan sekadar menemukan baris gagal.',
    status: 'Aktif',
  },
  {
    number: '05',
    title: 'REPL dan alat kerja',
    text: 'CLI menyediakan run, check, dan REPL. Extension VS Code menambahkan highlighting, snippet, ikon, serta perintah menjalankan dan memeriksa berkas.',
    status: 'Aktif',
  },
  {
    number: '06',
    title: 'Fondasi bahasa modern',
    text: 'Fungsi, rekursi, closure, daftar, kamus, pengindeksan Unicode, rentang inklusif, dan evaluasi short-circuit tersedia pada rilis awal.',
    status: 'Aktif',
  },
]

const docs = [
  {
    code: 'REF',
    title: 'Referensi bahasa',
    text: 'Sintaks, operator, tipe data, fungsi, dan semantik target Nusa.',
    href: `${github}/blob/main/docs/BAHASA.md`,
  },
  {
    code: 'ARC',
    title: 'Arsitektur interpreter',
    text: 'Alur lexer, parser, bytecode, mesin virtual, dan representasi nilai.',
    href: `${github}/blob/main/docs/ARSITEKTUR.md`,
  },
  {
    code: 'MAP',
    title: 'Peta jalan',
    text: 'Milestone implementasi dari toolchain hingga REPL dan dokumentasi akhir.',
    href: `${github}#peta-jalan-proyek`,
  },
  {
    code: 'CON',
    title: 'Kontribusi',
    text: 'Mulai dari isu, diskusi bahasa, dokumentasi, atau eksperimen runtime.',
    href: `${github}/issues`,
  },
  {
    code: 'SEC',
    title: 'Keamanan',
    text: 'Laporkan kerentanan melalui kanal privat pemelihara di GitHub.',
    href: `${github}/security`,
  },
]

const waypoints = [
  { label: 'Pulau 01', title: 'Bahasa Inti', meta: 'AKTIF · 0.1', state: 'active', text: 'Lexer, parser, evaluator, fungsi, kontrol alur, koleksi, dan diagnostik posisi sumber.' },
  { label: 'Pulau 02', title: 'Peralatan', meta: 'AKTIF · 0.1', state: 'active', text: 'CLI lintas platform, REPL, pemeriksaan sintaksis, pengujian, dan dukungan VS Code.' },
  { label: 'Pulau 03', title: 'Modul dan Paket', meta: 'TERENCANA · 0.2+', state: 'planned', text: 'Sistem modul, package manager, formatter, language server, dan debugger.' },
  { label: 'Pulau 04', title: 'Ekosistem Aplikasi', meta: 'HORIZON RISET', state: 'future', text: 'Pustaka web, desktop, mobile, game, FFI, dan distribusi biner terverifikasi.' },
]

export default function App() {
  const [menuOpen, setMenuOpen] = useState(false)
  const [activeSection, setActiveSection] = useState('beranda')

  useEffect(() => {
    const sections = navItems
      .map((item) => document.getElementById(item.id))
      .filter((section): section is HTMLElement => Boolean(section))

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0]
        if (visible) setActiveSection(visible.target.id)
      },
      { rootMargin: '-22% 0px -62% 0px', threshold: [0, 0.1, 0.3] },
    )

    sections.forEach((section) => observer.observe(section))
    return () => observer.disconnect()
  }, [])

  useEffect(() => {
    document.body.classList.toggle('menu-open', menuOpen)
    return () => document.body.classList.remove('menu-open')
  }, [menuOpen])

  return (
    <>
      <a className="skip-link" href="#main">Langsung ke konten</a>
      <header className="site-header">
        <a className="brand" href="#beranda" aria-label="NusaCode, kembali ke beranda">
          <img src="/assets/nusacode-logo.png" alt="" />
          <span><strong>NUSA</strong><small>CODE / ID</small></span>
        </a>

        <button
          className="menu-toggle"
          type="button"
          aria-expanded={menuOpen}
          aria-controls="site-nav"
          onClick={() => setMenuOpen((open) => !open)}
        >
          <span>{menuOpen ? 'Tutup' : 'Menu'}</span>
          <i aria-hidden="true" />
        </button>

        <nav id="site-nav" className={menuOpen ? 'nav-open' : ''} aria-label="Navigasi utama">
          {navItems.map((item) => (
            <a
              key={item.id}
              href={`#${item.id}`}
              className={activeSection === item.id ? 'active' : ''}
              aria-current={activeSection === item.id ? 'page' : undefined}
              onClick={() => setMenuOpen(false)}
            >
              {item.label}
            </a>
          ))}
          <a href={github} target="_blank" rel="noreferrer">GitHub <ArrowIcon /></a>
        </nav>

        <a className="support-link" href="https://trakteer.id/fira73" target="_blank" rel="noreferrer">
          Dukung proyek <ArrowIcon />
        </a>
      </header>

      <main id="main">
        <section className="hero" id="beranda" aria-labelledby="hero-title">
          <div className="hero-contours" aria-hidden="true" />
          <div className="hero-copy reveal">
            <div className="eyebrow"><span>Bahasa pemrograman orisinal</span><span>Indonesia · Pra-rilis</span></div>
            <h1 id="hero-title">Kode yang berbicara dalam <em>bahasa kita.</em></h1>
            <p className="hero-lead">
              NusaCode adalah bahasa pemrograman eksperimental dwibahasa dengan blok eksplisit,
              diagnostik Indonesia, dan interpreter referensi portabel yang dibangun dengan Rust.
            </p>
            <div className="hero-actions">
              <a className="button button-primary" href="#unduh">Mulai menjelajah <span aria-hidden="true">↓</span></a>
              <a className="button button-secondary" href={`${github}/blob/main/docs/BAHASA.md`} target="_blank" rel="noreferrer">Baca spesifikasi <ArrowIcon /></a>
            </div>
            <p className="honesty-note"><span aria-hidden="true" /> Rilis 0.1 adalah fondasi yang dapat dijalankan; API dan sintaks belum stabil sebelum 1.0.</p>
          </div>

          <figure className="hero-visual reveal delay-1">
            <div className="image-index" aria-hidden="true"><span>01</span><span>NUSANTARA / COMPUTING</span></div>
            <img src="/assets/nusacode-banner.jpg" alt="Ilustrasi biawak hijau, maskot NusaCode, dengan simbol kurung kurawal" />
            <figcaption>
              <span>IDENTITAS VISUAL</span>
              <span>BAHASA · RUNTIME · KOMUNITAS</span>
            </figcaption>
          </figure>
        </section>

        <section className="code-intro section-dark" aria-labelledby="code-title">
          <div className="section-heading light">
            <p className="section-kicker">01 / BAHASA</p>
            <h2 id="code-title">Sintaks yang terbaca.<br />Struktur yang tegas.</h2>
            <p>Nusa memadukan istilah yang dekat dengan penutur Indonesia dan batas blok yang terlihat jelas. Program berikut dapat langsung dijalankan oleh interpreter referensi.</p>
          </div>

          <div className="code-window">
            <div className="code-bar">
              <span>contoh/fibonacci.nusa</span>
              <CopyButton value={nusaExample} />
            </div>
            <pre aria-label="Contoh kode Nusa"><code>
              <span className="comment"># Deret Fibonacci dalam Nusa</span>{'\n'}
              <span className="keyword">fungsi</span> <span className="function">fibonacci</span>(n) <span className="keyword">maka</span>{'\n'}
              {'    '}<span className="keyword">jika</span> n &lt; <span className="number">2</span> <span className="keyword">maka</span>{'\n'}
              {'        '}<span className="keyword">kembalikan</span> n{'\n'}
              {'    '}<span className="keyword">akhir_jika</span>{'\n'}
              {'    '}<span className="keyword">kembalikan</span> <span className="function">fibonacci</span>(n - <span className="number">1</span>) + <span className="function">fibonacci</span>(n - <span className="number">2</span>){'\n'}
              <span className="keyword">akhir_fungsi</span>{'\n\n'}
              <span className="keyword">untuk</span> i <span className="keyword">dari</span> <span className="number">0</span> <span className="keyword">sampai</span> <span className="number">9</span> <span className="keyword">maka</span>{'\n'}
              {'    '}<span className="function">tulis</span>(<span className="function">fibonacci</span>(i)){'\n'}
              <span className="keyword">akhir_untuk</span>
            </code></pre>
            <div className="terminal-line"><span>$</span><code>cargo run --release -- examples/fungsi.nusa</code><span className="terminal-status">CLI aktif</span></div>
          </div>
        </section>

        <section className="features" aria-labelledby="feature-title">
          <div className="section-heading split">
            <div>
              <p className="section-kicker">02 / PRINSIP</p>
              <h2 id="feature-title">Dirancang untuk dipahami,<br />dibangun untuk diteliti.</h2>
            </div>
            <p>Nusa adalah ruang belajar terbuka: dari desain bahasa hingga mesin virtual. Status pada setiap bagian membedakan fondasi aktif, spesifikasi target, dan horizon riset.</p>
          </div>
          <div className="feature-ledger">
            {features.map((feature) => (
              <article key={feature.number}>
                <span className="feature-number">{feature.number}</span>
                <h3>{feature.title}</h3>
                <p>{feature.text}</p>
                <span className="status-label">{feature.status}</span>
              </article>
            ))}
          </div>
        </section>

        <section className="identity" aria-labelledby="identity-title">
          <div className="identity-mark" aria-hidden="true">
            <span>“</span>
            <div className="island-lines" />
          </div>
          <div className="identity-copy">
            <p className="section-kicker">03 / IDENTITAS</p>
            <h2 id="identity-title">Bukan terjemahan.<br />Sebuah cara pandang.</h2>
            <p className="identity-lead">Nusa tidak sekadar mengganti kata kunci bahasa lain. Penugasan <code>&lt;-</code>, perbandingan <code>=</code>, dan penutup blok eksplisit membentuk tata bahasa yang memiliki alasan desain sendiri.</p>
            <div className="identity-columns">
              <p><strong>Kejelasan</strong><br />Struktur harus dapat dibaca kembali tanpa menebak batas blok atau konteks tersembunyi.</p>
              <p><strong>Keterbukaan</strong><br />Bahasa tumbuh melalui dokumentasi, eksperimen, dan kritik teknis yang dapat ditinjau bersama.</p>
              <p><strong>Kedekatan</strong><br />Istilah Indonesia menurunkan jarak awal belajar tanpa mengurangi kedalaman ilmu komputasi.</p>
            </div>
          </div>
        </section>

        <section className="quickstart" id="unduh" aria-labelledby="quickstart-title">
          <div className="section-heading light compact">
            <p className="section-kicker">04 / MULAI</p>
            <h2 id="quickstart-title">Bangun dari sumber.</h2>
            <p>Interpreter referensi dibangun dengan Rust stabil dan berjalan pada Windows, Linux, serta macOS. Backend assembly x86-32 tetap tersedia sebagai jalur riset historis.</p>
          </div>
          <div className="install-panel">
            <div className="install-tabs"><span className="selected">Terminal</span><span>Lintas platform · Rust</span></div>
            <pre><code><span className="prompt">01</span> git clone https://github.com/hairift/Nusa-Code.git{`\n`}<span className="prompt">02</span> cd Nusa-Code{`\n`}<span className="prompt">03</span> cargo build --release{`\n`}<span className="prompt">04</span> cargo run --release -- examples/halo.nusa</code></pre>
            <CopyButton value={buildCommand} label="Salin perintah" />
          </div>
          <div className="quickstart-foot">
            <p><strong>Catatan:</strong> rilis pra-1.0 belum menjamin kompatibilitas sintaks atau API. Gunakan versi yang dikunci untuk proyek penting.</p>
            <a href={`${github}#cara-membangun`} target="_blank" rel="noreferrer">Panduan build lengkap <ArrowIcon /></a>
          </div>
        </section>

        <section className="docs" id="dokumentasi" aria-labelledby="docs-title">
          <div className="section-heading split">
            <div>
              <p className="section-kicker">05 / DOKUMENTASI</p>
              <h2 id="docs-title">Peta pengetahuan Nusa.</h2>
            </div>
            <p>Masuk melalui spesifikasi bahasa, telusuri mesin virtual, lalu ikut menentukan langkah berikutnya.</p>
          </div>
          <div className="docs-list">
            {docs.map((doc) => (
              <a key={doc.code} href={doc.href} target="_blank" rel="noreferrer">
                <span className="doc-code">{doc.code}</span>
                <span><strong>{doc.title}</strong><small>{doc.text}</small></span>
                <ArrowIcon />
              </a>
            ))}
          </div>
        </section>

        <section className="archipelago section-dark" id="ekosistem" aria-labelledby="roadmap-title">
          <div className="archipelago-header">
            <div>
              <p className="section-kicker">06 / RUTE PENGEMBANGAN</p>
              <h2 id="roadmap-title">Dari satu mesin,<br />menuju sebuah ekosistem.</h2>
            </div>
            <p>Setiap “pulau” adalah lapisan kerja yang dapat dipelajari dan dikembangkan secara terukur. Rute ini bukan janji tanggal rilis.</p>
          </div>

          <div className="route-layout">
            <ol className="route-list">
              {waypoints.map((waypoint, index) => (
                <li key={waypoint.title} className={waypoint.state}>
                  <span className="route-node" aria-hidden="true">{String(index + 1).padStart(2, '0')}</span>
                  <div>
                    <span className="route-label">{waypoint.label}</span>
                    <h3>{waypoint.title}</h3>
                    <p>{waypoint.text}</p>
                  </div>
                  <span className="route-meta">{waypoint.meta}</span>
                </li>
              ))}
            </ol>

            <aside className="runtime-console" aria-label="Status runtime Nusa">
              <div className="console-top"><span>NUSA / RUNTIME STATUS</span><span>ref. 0.1</span></div>
              <div className="console-body">
                <p><span className="console-prompt">nusa@vm:~$</span> status --verbose</p>
                <dl>
                  <div><dt>runtime</dt><dd>Rust interpreter <i>aktif</i></dd></div>
                  <div><dt>frontend</dt><dd>lexer + parser <i>aktif</i></dd></div>
                  <div><dt>repl_cli</dt><dd>run + check <i>aktif</i></dd></div>
                  <div><dt>editor</dt><dd>VS Code support <i>aktif</i></dd></div>
                  <div><dt>package_manager</dt><dd>roadmap 0.2+ <i className="future">riset</i></dd></div>
                </dl>
                <p className="console-output">4 komponen aktif · 1 lintasan riset</p>
                <span className="cursor" aria-hidden="true" />
              </div>
            </aside>
          </div>
        </section>

        <section className="creator" aria-labelledby="creator-title">
          <div className="creator-index" aria-hidden="true">07</div>
          <div className="creator-copy">
            <p className="section-kicker">PENCIPTA / KONTRIBUTOR</p>
            <h2 id="creator-title">Dibangun dengan rasa ingin tahu,<br />dibuka untuk tumbuh bersama.</h2>
            <div className="creator-details">
              <div>
                <span>INISIATOR PROYEK</span>
                <strong>Muhammad Arif Triyana</strong>
                <p>Mahasiswa Teknik Informatika<br />Universitas Catur Insan Cendekia</p>
              </div>
              <p>Nusa bermula dari pertanyaan sederhana: seperti apa bahasa pemrograman yang tumbuh dari cara kita menjelaskan logika? Proyek ini mengundang mahasiswa, pendidik, peneliti, dan pengembang untuk ikut mengujinya.</p>
            </div>
            <a className="text-link" href={`${github}/issues`} target="_blank" rel="noreferrer">Temukan ruang kontribusi <ArrowIcon /></a>
          </div>
        </section>

        <section className="donation" aria-labelledby="donation-title">
          <div className="donation-symbol" aria-hidden="true">{`{ }`}</div>
          <div>
            <p className="section-kicker">DUKUNG PENELITIAN TERBUKA</p>
            <h2 id="donation-title">Bantu Nusa menyeberang<br />ke pulau berikutnya.</h2>
          </div>
          <div className="donation-action">
            <p>Dukungan Anda membantu waktu riset, dokumentasi, pengujian, dan penyediaan materi belajar yang tetap terbuka.</p>
            <a className="button button-amber" href="https://trakteer.id/fira73" target="_blank" rel="noreferrer">Dukung via Trakteer <ArrowIcon /></a>
          </div>
        </section>
      </main>

      <footer>
        <div className="footer-brand">
          <img src="/assets/nusacode-logo.png" alt="" />
          <div><strong>NusaCode</strong><span>Bahasa dari Indonesia, untuk siapa saja.</span></div>
        </div>
        <div className="footer-links">
          <div><strong>PROYEK</strong><a href={github} target="_blank" rel="noreferrer">GitHub</a><a href={`${github}/issues`} target="_blank" rel="noreferrer">Issues</a><a href={`${github}/releases`} target="_blank" rel="noreferrer">Releases</a></div>
          <div><strong>DOKUMEN</strong><a href={`${github}/blob/main/docs/BAHASA.md`} target="_blank" rel="noreferrer">Bahasa</a><a href={`${github}/blob/main/docs/ARSITEKTUR.md`} target="_blank" rel="noreferrer">Arsitektur</a><a href={`${github}#peta-jalan-proyek`} target="_blank" rel="noreferrer">Roadmap</a></div>
          <div><strong>KOMUNITAS</strong><a href={`${github}/discussions`} target="_blank" rel="noreferrer">Diskusi</a><a href="https://trakteer.id/fira73" target="_blank" rel="noreferrer">Trakteer</a></div>
        </div>
        <div className="footer-bottom">
          <span>© 2026 NusaCode. Proyek sumber terbuka.</span>
          <span>Pra-rilis · Dibangun di Cirebon, Indonesia</span>
        </div>
      </footer>
    </>
  )
}
