/* ============================================================
   MARIA Medical Center — shared site chrome + i18n + social.
   Injects a modern topbar (nav + RU/UK/EN switch + social) and a
   floating quick-contact button onto every inner page. Cached once,
   reused everywhere. Homepage has its own chrome and does NOT load this.

   To edit social links — change SOCIAL below (single source of truth).
   ============================================================ */
(function () {
  "use strict";

  var SOCIAL = {
    telegramBot:     "https://t.me/SSVPROFF_MEDICAL_BOT",
    whatsapp:        "https://wa.me/380675707949",
    viber:           "viber://chat?number=+380675707949",
    phone:           "tel:+380675707949",
    instagram:       "https://www.instagram.com/suhovssv/",
    threads:         "https://www.threads.com/@suhovssv",
    facebook:        "https://www.facebook.com/sergsv1963",
    fbGroup:         "https://www.facebook.com/groups/718534880901906",
    youtube:         "https://www.youtube.com/@SSVproff-22.06",
    telegramChannel: ""   // добавить при наличии
  };

  var T = {
    ru: { home:"Главная", services:"Услуги", articles:"Статьи", book:"Запись",
          bookNow:"Записаться", quick:"Связаться", call:"Позвонить", tg:"Telegram", wa:"WhatsApp",
          crumbHome:"Главная", crumbArticles:"Статьи",
          formTitle:"📅 Записаться на консультацию", fName:"Ваше имя *", fPhone:"Телефон *",
          fEmail:"Email", fMsg:"Комментарий", fSubmit:"📞 Отправить заявку",
          bookTg:"📱 Запись через Telegram", backHome:"← На главную", backAll:"📚 Все статьи",
          phName:"Иван Иванов", phMsg:"Опишите симптомы или вопросы..." },
    uk: { home:"Головна", services:"Послуги", articles:"Статті", book:"Запис",
          bookNow:"Записатися", quick:"Зв'язатися", call:"Зателефонувати", tg:"Telegram", wa:"WhatsApp",
          crumbHome:"Головна", crumbArticles:"Статті",
          formTitle:"📅 Записатися на консультацію", fName:"Ваше ім'я *", fPhone:"Телефон *",
          fEmail:"Email", fMsg:"Коментар", fSubmit:"📞 Надіслати заявку",
          bookTg:"📱 Запис через Telegram", backHome:"← На головну", backAll:"📚 Усі статті",
          phName:"Іван Іванов", phMsg:"Опишіть симптоми або запитання..." },
    en: { home:"Home", services:"Services", articles:"Articles", book:"Appointment",
          bookNow:"Book now", quick:"Contact", call:"Call", tg:"Telegram", wa:"WhatsApp",
          crumbHome:"Home", crumbArticles:"Articles",
          formTitle:"📅 Book a consultation", fName:"Your name *", fPhone:"Phone *",
          fEmail:"Email", fMsg:"Comment", fSubmit:"📞 Send request",
          bookTg:"📱 Book via Telegram", backHome:"← Home", backAll:"📚 All articles",
          phName:"John Smith", phMsg:"Describe symptoms or questions..." }
  };

  var els = {};
  var current = "ru";

  function detectLang() {
    var p = new URLSearchParams(location.search).get("lang");
    if (p && T[p]) return p;
    try { var s = localStorage.getItem("lang"); if (s && T[s]) return s; } catch (e) {}
    var n = (navigator.language || "ru").slice(0, 2);
    return T[n] ? n : "ru";
  }

  function setLang(lang) {
    if (!T[lang]) lang = "ru";
    current = lang;
    var t = T[lang];
    document.documentElement.lang = lang;
    if (els.navHome)  els.navHome.textContent = t.home;
    if (els.navArt)   els.navArt.textContent = t.articles;
    if (els.navBook)  els.navBook.textContent = t.book;
    if (els.cta)      els.cta.textContent = t.bookNow;
    if (els.faCall)   els.faCall.querySelector(".ssv-lbl").textContent = t.call;
    if (els.faTg)     els.faTg.querySelector(".ssv-lbl").textContent = t.tg;
    if (els.faWa)     els.faWa.querySelector(".ssv-lbl").textContent = t.wa;
    // translate any page-level opt-in nodes
    document.querySelectorAll("[data-ssv-i18n]").forEach(function (el) {
      var v = t[el.getAttribute("data-ssv-i18n")];
      if (v) el.textContent = v;
    });
    document.querySelectorAll("[data-ssv-i18n-ph]").forEach(function (el) {
      var v = t[el.getAttribute("data-ssv-i18n-ph")];
      if (v) el.setAttribute("placeholder", v);
    });
    els.langBtns && els.langBtns.forEach(function (b) {
      b.classList.toggle("active", b.getAttribute("data-lang") === lang);
    });
    // per-page translated article bodies: show only the active language block
    var blocks = document.querySelectorAll("[data-lang-content]");
    if (blocks.length) {
      var hasLang = false;
      blocks.forEach(function (el) { if (el.getAttribute("data-lang-content") === lang) hasLang = true; });
      var shown = hasLang ? lang : "ru";
      blocks.forEach(function (el) {
        el.style.display = el.getAttribute("data-lang-content") === shown ? "" : "none";
      });
    }
    try { localStorage.setItem("lang", lang); } catch (e) {}
    var u = new URL(location); u.searchParams.set("lang", lang);
    history.replaceState(null, "", u);
  }

  function a(href, html, cls, title) {
    var e = document.createElement("a");
    e.href = href; e.innerHTML = html; if (cls) e.className = cls;
    if (title) e.title = title;
    if (/^https?:/.test(href)) { e.target = "_blank"; e.rel = "noopener"; }
    return e;
  }

  function buildTopbar() {
    var bar = document.createElement("div");
    bar.className = "ssv-topbar";

    var brand = a("/", '<span class="ssv-logo">🏥</span><span><b>MARIA</b><span>Medical Center</span></span>', "ssv-brand");
    bar.appendChild(brand);

    var nav = document.createElement("nav"); nav.className = "ssv-nav";
    els.navHome = a("/", "Главная"); nav.appendChild(els.navHome);
    els.navArt  = a("/articles/", "Статьи"); nav.appendChild(els.navArt);
    els.navBook = a("/#appointment", "Запись"); nav.appendChild(els.navBook);
    bar.appendChild(nav);

    var right = document.createElement("div"); right.className = "ssv-right";

    var social = document.createElement("div"); social.className = "ssv-social";
    [["telegramBot","✈️","#0088cc","Telegram"],
     ["instagram","📷","#DD2A7B","Instagram"],
     ["facebook","f","#1877F2","Facebook"],
     ["fbGroup","👥","#0866FF","SSVproff"]].forEach(function (s) {
      if (SOCIAL[s[0]]) { var l = a(SOCIAL[s[0]], s[1], "", s[3]); l.style.background = s[2]; social.appendChild(l); }
    });
    right.appendChild(social);

    var lang = document.createElement("div"); lang.className = "ssv-lang";
    els.langBtns = [];
    [["ru","RU"],["uk","UA"],["en","EN"]].forEach(function (l) {
      var b = document.createElement("button");
      b.type = "button"; b.textContent = l[1]; b.setAttribute("data-lang", l[0]);
      b.addEventListener("click", function () { setLang(l[0]); });
      els.langBtns.push(b); lang.appendChild(b);
    });
    right.appendChild(lang);

    els.cta = a("/#appointment", "Записаться", "ssv-cta");
    right.appendChild(els.cta);

    bar.appendChild(right);
    document.body.insertBefore(bar, document.body.firstChild);

    addEventListener("scroll", function () {
      bar.classList.toggle("ssv-scrolled", scrollY > 20);
    });
  }

  function fabAction(href, icon, bg, key) {
    var e = a(href, '<i style="background:' + bg + '">' + icon + '</i><span class="ssv-lbl"></span>');
    return e;
  }

  function buildFab() {
    var fab = document.createElement("div"); fab.className = "ssv-fab";
    var actions = document.createElement("div"); actions.className = "ssv-fab-actions";
    els.faTg   = fabAction(SOCIAL.telegramBot, "✈️", "#0088cc", "tg");
    els.faWa   = fabAction(SOCIAL.whatsapp, "💬", "#25D366", "wa");
    els.faCall = fabAction(SOCIAL.phone, "📞", "#6B5B95", "call");
    actions.appendChild(els.faTg); actions.appendChild(els.faWa); actions.appendChild(els.faCall);
    var toggle = document.createElement("button");
    toggle.type = "button"; toggle.className = "ssv-fab-toggle"; toggle.innerHTML = "💬";
    toggle.setAttribute("aria-label", "Contact");
    toggle.addEventListener("click", function () { fab.classList.toggle("open"); });
    fab.appendChild(actions); fab.appendChild(toggle);
    document.body.appendChild(fab);
  }

  function init() {
    buildTopbar();
    buildFab();
    setLang(detectLang());
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
