#!/usr/bin/env python3
"""Generate neutral client-facing e-commerce platform concept report (no brand/logo)."""

from __future__ import annotations

from datetime import date
from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.lib import colors
from reportlab.lib.enums import TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
)
from reportlab.platypus.flowables import Flowable

OUTPUT = Path(r"C:\Users\pc\Desktop\App-Concept-Report.pdf")
FONT_REG = r"C:\Windows\Fonts\tahoma.ttf"
FONT_BOLD = r"C:\Windows\Fonts\tahomabd.ttf"

# Neutral professional palette (reference lecture style — no client/ZADAK branding)
PRIMARY = colors.HexColor("#2E6B5A")
ACCENT = colors.HexColor("#3D8B72")
ACCENT_LIGHT = colors.HexColor("#4A9E85")
TEXT_PRIMARY = colors.HexColor("#1E2A28")
TEXT_SECONDARY = colors.HexColor("#4A5654")
TEXT_MUTED = colors.HexColor("#7A8684")
BOX_BG = colors.HexColor("#F4F8F6")
BOX_BORDER = colors.HexColor("#D4E4DE")
HIGHLIGHT_BG = colors.HexColor("#EAF4EF")
DIVIDER = colors.HexColor("#2E6B5A")

PAGE_W, PAGE_H = A4
MARGIN_L = 18 * mm
MARGIN_R = 18 * mm
MARGIN_T = 16 * mm
MARGIN_B = 18 * mm
CONTENT_W = PAGE_W - MARGIN_L - MARGIN_R


def ar(text: str) -> str:
    if not text:
        return ""
    return get_display(arabic_reshaper.reshape(text))


def register_fonts() -> None:
    pdfmetrics.registerFont(TTFont("Tahoma", FONT_REG))
    pdfmetrics.registerFont(TTFont("Tahoma-Bold", FONT_BOLD))


class RoundedBox(Flowable):
    def __init__(self, content, width, accent=PRIMARY, bg=BOX_BG, pad=10, radius=8, bar_w=4):
        super().__init__()
        self.content = content
        self.width = width
        self.accent = accent
        self.bg = bg
        self.pad = pad
        self.radius = radius
        self.bar_w = bar_w
        self._height = 0

    def wrap(self, avail_w, avail_h):
        inner_w = self.width - 2 * self.pad - self.bar_w - 4
        y = self.pad
        for item in self.content:
            iw, ih = item.wrap(inner_w, avail_h)
            item._box_x = self.pad + self.bar_w + 4
            item._box_y = y
            y += ih + 4
        self._height = y + self.pad
        return self.width, self._height

    def draw(self):
        c = self.canv
        c.saveState()
        c.setFillColor(self.bg)
        c.setStrokeColor(BOX_BORDER)
        c.setLineWidth(0.6)
        c.roundRect(0, 0, self.width, self._height, self.radius, fill=1, stroke=1)
        c.setFillColor(self.accent)
        c.roundRect(self.width - self.bar_w - 2, 2, self.bar_w, self._height - 4, 2, fill=1, stroke=0)
        for item in self.content:
            item.drawOn(c, getattr(item, "_box_x", self.pad), self._height - getattr(item, "_box_y", self.pad) - item.height)
        c.restoreState()


class SectionTitle(Flowable):
    def __init__(self, title: str, width: float, accent: colors.Color = PRIMARY):
        super().__init__()
        self.title = title
        self.width = width
        self.accent = accent
        self._height = 22

    def wrap(self, aW, aH):
        return self.width, self._height

    def draw(self):
        c = self.canv
        c.saveState()
        c.setFillColor(self.accent)
        c.rect(self.width - 5, 2, 4, 16, fill=1, stroke=0)
        c.setFont("Tahoma-Bold", 13)
        c.setFillColor(self.accent)
        c.drawRightString(self.width - 12, 4, self.title)
        c.restoreState()


class PillBadge(Flowable):
    def __init__(self, text: str, width: float = 120, height: float = 22):
        super().__init__()
        self.text = text
        self.badge_w = width
        self.badge_h = height
        self.width = CONTENT_W
        self._height = height + 4

    def wrap(self, aW, aH):
        return self.width, self._height

    def draw(self):
        c = self.canv
        x = (self.width - self.badge_w) / 2
        c.saveState()
        c.setFillColor(PRIMARY)
        c.roundRect(x, 0, self.badge_w, self.badge_h, self.badge_h / 2, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont("Tahoma-Bold", 9)
        c.drawCentredString(x + self.badge_w / 2, 6, self.text)
        c.restoreState()


class HorizontalRule(Flowable):
    def __init__(self, width: float):
        super().__init__()
        self.width = width
        self._height = 8

    def wrap(self, aW, aH):
        return self.width, self._height

    def draw(self):
        c = self.canv
        c.saveState()
        c.setStrokeColor(DIVIDER)
        c.setLineWidth(1.2)
        c.line(0, 4, self.width, 4)
        c.restoreState()


class TocBox(Flowable):
    def __init__(self, title: str, items: list[str], width: float):
        super().__init__()
        self.title = title
        self.items = items
        self.width = width
        self._height = 0

    def wrap(self, aW, aH):
        self._height = 28 + len(self.items) * 16 + 12
        return self.width, self._height

    def draw(self):
        c = self.canv
        c.saveState()
        c.setFillColor(HIGHLIGHT_BG)
        c.setStrokeColor(BOX_BORDER)
        c.setLineWidth(0.6)
        c.roundRect(0, 0, self.width, self._height, 10, fill=1, stroke=1)
        c.setFont("Tahoma-Bold", 12)
        c.setFillColor(PRIMARY)
        c.drawRightString(self.width - 14, self._height - 22, self.title)
        y = self._height - 40
        c.setFont("Tahoma", 10)
        c.setFillColor(TEXT_PRIMARY)
        for item in self.items:
            c.drawRightString(self.width - 14, y, item)
            y -= 16
        c.restoreState()


def p(text: str, size: float = 10, bold: bool = False, color: colors.Color = TEXT_PRIMARY) -> Paragraph:
    font = "Tahoma-Bold" if bold else "Tahoma"
    style = ParagraphStyle(
        name=f"ar_{size}_{bold}",
        fontName=font,
        fontSize=size,
        leading=size * 1.55,
        alignment=TA_RIGHT,
        textColor=color,
        wordWrap="RTL",
    )
    return Paragraph(text, style)


def labeled(label: str, body: str, size: float = 10.5) -> Paragraph:
    return p(f"<b>{ar(label)}</b> {ar(body)}", size=size)


def bullet_block(items: list[str], size: float = 10) -> list[Flowable]:
    lines = []
    for item in items:
        lines.append(p(f"• {item}", size=size))
        lines.append(Spacer(1, 2))
    return lines


def content_box(paragraphs: list[Flowable], accent: colors.Color = PRIMARY) -> RoundedBox:
    return RoundedBox(paragraphs, CONTENT_W, accent=accent)


def section(title: str, paragraphs: list[Flowable], accent: colors.Color = PRIMARY) -> list[Flowable]:
    return [
        Spacer(1, 8),
        SectionTitle(title, CONTENT_W, accent),
        Spacer(1, 4),
        content_box(paragraphs, accent),
    ]


def build_story() -> list:
    today = date.today().strftime("%d / %m / %Y")
    story: list = []

    story.append(PillBadge(ar("عرض فكرة مشروع"), width=120))
    story.append(Spacer(1, 16))
    story.append(
        Paragraph(
            ar("منصة تجارة إلكترونية متكاملة"),
            ParagraphStyle("cover_title", fontName="Tahoma-Bold", fontSize=20, leading=28, alignment=1, textColor=TEXT_PRIMARY),
        )
    )
    story.append(Spacer(1, 6))
    story.append(
        Paragraph(
            ar("شرح شامل لفكرة التطبيق — الأدوار — الميزات — مسارات الاستخدام"),
            ParagraphStyle("cover_sub", fontName="Tahoma", fontSize=12, leading=18, alignment=1, textColor=ACCENT),
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        Paragraph(
            ar(f"تاريخ الإعداد: {today}"),
            ParagraphStyle("cover_meta", fontName="Tahoma", fontSize=9, leading=12, alignment=1, textColor=TEXT_MUTED),
        )
    )
    story.append(Spacer(1, 12))
    story.append(HorizontalRule(CONTENT_W))
    story.append(Spacer(1, 10))

    toc = [
        ar("1. ما هي فكرة المنصة؟"),
        ar("2. لماذا هذا النموذج؟ — القيمة التجارية"),
        ar("3. الأطراف الثلاثة — من يستخدم ماذا؟"),
        ar("4. رحلة الزبون — من التصفّح إلى الاستلام"),
        ar("5. رحلة البائع — من الاشتراك إلى البيع"),
        ar("6. لوحة الإدارة — التحكم الكامل"),
        ar("7. الميزات الأساسية بالتفصيل"),
        ar("8. الطلبات والدفع والتوصيل"),
        ar("9. التسويق والإشعارات"),
        ar("10. البنية التقنية — نظرة عامة"),
        ar("11. القدرة الاستيعابية"),
        ar("12. الخلاصة — ماذا يحصل العميل؟"),
    ]
    story.append(TocBox(ar("فهرس المحتويات"), toc, CONTENT_W))
    story.append(PageBreak())

    story.extend(
        section(
            ar("الفصل الأول: ما هي فكرة المنصة؟"),
            [
                labeled(
                    "التعريف:",
                    "تطبيق جوّال للتجارة الإلكترونية يربط ثلاثة أطراف: الزبائن الذين "
                    "يريدون الشراء، والتجّار (البائعون) الذين يريدون عرض منتجاتهم، "
                    "والإدارة التي تشرف على المنصة بالكامل. المنصة ليست متجراً "
                    "لواحد — بل سوقاً رقمياً (Marketplace) يجمع عدة بائعين تحت "
                    "سقف واحد مع تجربة موحّدة للزبون.",
                ),
                Spacer(1, 6),
                labeled(
                    "الفكرة الأساسية:",
                    "الزبون يفتح التطبيق → يتصفّح منتجات من بائعين مختلفين → "
                    "يضيف للسلة → يدفع → يتابع توصيل طلبه. البائع يعرض منتجاته "
                    "بعد موافقة الإدارة وضمن اشتراك نشط. الإدارة تتحكم بكل شيء: "
                    "من الموافقة على المنتجات إلى إدارة الطلبات والمبيعات والعروض.",
                ),
                Spacer(1, 6),
                labeled(
                    "لماذا تطبيق وليس موقع فقط؟",
                    "التجربة على الجوال أسرع وأقرب للمستخدم العربي. الإشعارات "
                    "الفورية (Push) تُبقي الزبون والبائع على اطلاع. التطبيق يعمل "
                    "على Android و iOS من قاعدة كود واحدة (Flutter).",
                ),
            ],
        )
    )

    story.extend(
        section(
            ar("الفصل الثاني: لماذا هذا النموذج؟ — القيمة التجارية"),
            [
                labeled(
                    "لصاحب المنصة (العميل):",
                    "مصدر دخل متعدد: اشتراكات البائعين + عمولات (اختياري) + "
                    "إعلانات وشرائح رئيسية + كوبونات مدفوعة. تحكم كامل بالجودة "
                    "عبر موافقة المنتجات. بيانات واضحة عن المبيعات والطلبات.",
                ),
                Spacer(1, 6),
                labeled(
                    "للزبون:",
                    "تجربة تسوق واحدة تجمع عدة متاجر. بحث وفلترة سهلة. "
                    "تتبّع الطلب حتى الباب. طرق دفع متعددة (شام كاش / "
                    "الدفع عند الاستلام).",
                ),
                Spacer(1, 6),
                labeled(
                    "للبائع:",
                    "واجهة جاهزة بدون بناء تطبيق خاص. إدارة منتجات من الجوال. "
                    "ظهور أمام آلاف الزبائن. نظام اشتراك واضح يحدد مدة البيع.",
                ),
                Spacer(1, 6),
                labeled(
                    "الفرق عن متجر تقليدي:",
                    "المتجر التقليدي = بائع واحد + كatalog ثابت. هذه المنصة = "
                    "عدة بائعين + إدارة مركزية + workflow موافقة + اشتراكات + "
                    "تقارير + إشعارات جماعية.",
                ),
            ],
            ACCENT,
        )
    )
    story.append(PageBreak())

    story.extend(
        section(
            ar("الفصل الثالث: الأطراف الثلاثة — من يستخدم ماذا؟"),
            [
                p(ar("① الزبون (Customer)"), size=11, bold=True, color=ACCENT_LIGHT),
                Spacer(1, 3),
                p(
                    ar(
                        "ينشئ حسابه بنفسه (تسجيل + OTP أو Google). يتصفّح، يشتري، "
                        "يتابع طلباته. لا يرى لوحة إدارية ولا يضيف منتجات. "
                        "المفضّلة محفوظة على جهازه. يغيّر كلمة مروره بنفسه."
                    ),
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("② البائع (Seller)"), size=11, bold=True, color=ACCENT),
                Spacer(1, 3),
                labeled(
                    "حساب يُنشئه المدير فقط:",
                    "لا يمكن للبائع التسجيل الذاتي — الإدارة تختار من يدخل "
                    "المنصة. يضيف منتجات → تنتظر موافقة → تظهر للزبائن. "
                    "اشتراك شهري/سنوي يحدد إمكانية البيع. تنبيه قبل 3 أيام "
                    "من انتهاء الاشتراك. البريد والهاتف للقراءة فقط — "
                    "المدير يعيد كلمة المرور.",
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("③ المدير (Admin)"), size=11, bold=True, color=PRIMARY),
                Spacer(1, 3),
                p(
                    ar(
                        "العقل المدبّر للمنصة: يوافق/يرفض المنتجات، يدير الطلبات "
                        "(موافقة دفع — رفض — وقت توصيل — تأكيد وصول)، ينشئ "
                        "البائعين ويجدّد اشتراكاتهم، يدير الفئات والكوبونات "
                        "والشرائح الرئيسية، يبث إشعارات لجميع المستخدمين، "
                        "ويراجع تقارير المبيعات."
                    ),
                    size=10,
                ),
            ],
        )
    )

    story.extend(
        section(
            ar("الفصل الرابع: رحلة الزبون — من التصفّح إلى الاستلام"),
            bullet_block(
                [
                    ar("1. أول تشغيل: شاشة ترحيب + شرح سريع (Onboarding)"),
                    ar("2. تسجيل دخول أو إنشاء حساب (بريد + OTP أو Google)"),
                    ar("3. الصفحة الرئيسية: شرائح إعلانية — فئات — منتجات مميّزة — توصيل مجاني"),
                    ar("4. تصفّح: فئات → تصنيفات فرعية → منتجات → تفاصيل المنتج → صفحة المتجر"),
                    ar("5. بحث متقدّم: كلمات مفتاحية + فلتر (سعر — فئة — ...)"),
                    ar("6. إضافة للسلة → مراجعة السلة → اختيار العنوان"),
                    ar("7. الدفع: شام كاش (تحويل + موافقة إدارية) أو الدفع عند الاستلام"),
                    ar("8. تطبيق كوبون خصم (إن وُجد) قبل تأكيد الطلب"),
                    ar("9. تأكيد الطلب → إشعار → متابعة في «طلباتي»"),
                    ar("10. تتبّع حالة الطلب: pending → paid → processing → shipped → delivered"),
                    ar("11. استلام الطلب → تأكيد الاستلام من التطبيق"),
                    ar("12. الملف الشخصي: تعديل الاسم/الهاتف/البريد — مفضّلة — إشعارات — مظهر — لغة"),
                ],
                size=9.8,
            ),
            ACCENT_LIGHT,
        )
    )
    story.append(PageBreak())

    story.extend(
        section(
            ar("الفصل الخامس: رحلة البائع — من الاشتراك إلى البيع"),
            bullet_block(
                [
                    ar("1. الإدارة تنشئ حساب البائع (اسم — بريد — هاتف — كلمة مرور — مدة اشتراك)"),
                    ar("2. البائع يسجّل دخول → يرى لوحة «منتجاتي» و«اشتراكاتي»"),
                    ar("3. إضافة منتج: صور — عنوان — وصف — سعر — فئة — كمية"),
                    ar("4. المنتج يذهب لـ «طلبات الموافقة» عند الإدارة"),
                    ar("5. الإدارة توافق → المنتج يظهر في المتجر | ترفض → لا يظهر"),
                    ar("6. تعديل أو حذف منتج = طلب جديد يحتاج موافقة"),
                    ar("7. اشتراك نشط = يمكن البيع | منتهٍ = المنتجات تختفي"),
                    ar("8. تنبيه قبل 3 أيام من انتهاء الاشتراك (داخل التطبيق + Push)"),
                    ar("9. البائع لا يغيّر بريده/هاتفه — الإدارة تتحكم ببيانات التواصل"),
                ],
                size=9.8,
            ),
            ACCENT,
        )
    )

    story.extend(
        section(
            ar("الفصل السادس: لوحة الإدارة — التحكم الكامل"),
            bullet_block(
                [
                    ar("الطلبات: عرض كل الطلبات — موافقة الدفع (شام كاش) — رفض — تحديد وقت توصيل — إشعار الزبون — تأكيد وصول"),
                    ar("المبيعات: تقارير — إحصائيات — فلترة حسب التاريخ والبائع"),
                    ar("المستخدمون: قائمة الزبائن المسجّلين"),
                    ar("البائعون: إنشاء — تجديد اشتراك — حظر — إلغاء — إعادة كلمة مرور"),
                    ar("الفئات: إنشاء/تعديل/حذف فئات وتصنيفات فرعية"),
                    ar("شرائح الرئيسية: صور/عناوين/روابط للصفحة الأولى"),
                    ar("الكوبونات: نسبة أو مبلغ ثابت — تاريخ انتهاء — حد استخدام"),
                    ar("اشتراكات التوصيل المجاني: ربط بائع محدّد بعرض توصيل مجاني"),
                    ar("موافقة المنتجات: قائمة طلبات البائعين — قبول/رفض"),
                    ar("بث إشعار: رسالة لجميع المستخدمين أو فئة محددة"),
                ],
                size=9.8,
            ),
            PRIMARY,
        )
    )
    story.append(PageBreak())

    story.extend(
        section(
            ar("الفصل السابع: الميزات الأساسية بالتفصيل"),
            [
                p(ar("المصادقة والحسابات"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "تسجيل بالبريد + OTP للتحقق — تسجيل دخول Google — "
                        "نسيان/تغيير كلمة المرور — tokens آمنة — "
                        "3 أدوار منفصلة (customer / seller / admin) — "
                        "كل دور يرى شاشات مختلفة في نفس التطبيق."
                    ),
                    size=9.8,
                ),
                Spacer(1, 6),
                p(ar("التسوّق والكتalog"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "فئات متعددة المستويات — صور منتجات — أسعار — وصف — "
                        "منتجات مميّزة متناوبة على الرئيسية — بحث نصي — "
                        "فلترة — صفحة تفاصيل متجر لكل بائع — "
                        "cache للأداء."
                    ),
                    size=9.8,
                ),
                Spacer(1, 6),
                p(ar("السلة والدفع"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "سلة مشتريات — تعديل الكميات — كوبونات — "
                        "عنوان توصيل (محافظات) — Sham Cash + COD — "
                        "تأكيد الطلب — إيميل/إشعار تأكيد."
                    ),
                    size=9.8,
                ),
                Spacer(1, 6),
                p(ar("الاشتراكات والجودة"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "workflow موافقة المنتجات — اشتراك البائع — "
                        "تذكير انتهاء — اشتراك توصيل مجاني — "
                        "حظر/إلغاء بائع — reset password للبائعين."
                    ),
                    size=9.8,
                ),
            ],
            ACCENT,
        )
    )

    story.extend(
        section(
            ar("الفصل الثامن: الطلبات والدفع والتوصيل"),
            [
                labeled(
                    "دورة حياة الطلب:",
                    "① الزبون يُنشئ الطلب → ② pending (بانتظار الدفع) → "
                    "③ paid (تم الدفع/الموافقة) → ④ processing (قيد التجهيز) → "
                    "⑤ shipped (في الطريق) → ⑥ delivered (تم التسليم) → "
                    "⑦ الزبون يؤكّد الاستلام.",
                ),
                Spacer(1, 6),
                labeled(
                    "شام كاش:",
                    "الزبون يحوّل المبلغ → يرفع إثبات (اختياري) → "
                    "الإدارة تتأكد وتوافق على الدفع → الطلب ينتقل للتجهيز.",
                ),
                Spacer(1, 6),
                labeled(
                    "الدفع عند الاستلام (COD):",
                    "الطلب يُقبل مباشرة → التوصيل → الدفع للمندوب.",
                ),
                Spacer(1, 6),
                labeled(
                    "التوصيل:",
                    "الإدارة تحدّد وقت التوصيل → إشعار للزبون → "
                    "تتبّع من التطبيق → تأكيد الاستلام.",
                ),
            ],
            ACCENT_LIGHT,
        )
    )
    story.append(PageBreak())

    story.extend(
        section(
            ar("الفصل التاسع: التسويق والإشعارات"),
            bullet_block(
                [
                    ar("شرائح الصفحة الرئيسية — بanners قابلة للتعديل من الإدارة"),
                    ar("منتجات مميّزة — rotation تلقائي على الرئيسية"),
                    ar("كوبونات خصم — نسبة مئوية أو مبلغ — تاريخ انتهاء"),
                    ar("اشتراك توصيل مجاني — لبائعين محدّدين"),
                    ar("إشعارات Push (FCM) — داخل التطبيق — unread count"),
                    ar("بث إشعار عام — رسالة لكل المستخدمين"),
                    ar("إشعارات الطلبات — وقت توصيل — موافقة دفع — وصول"),
                    ar("تذكير اشتراك البائع — 3 أيام قبل الانتهاء"),
                ],
                size=9.8,
            ),
            PRIMARY,
        )
    )

    story.extend(
        section(
            ar("الفصل العاشر: البنية التقنية — نظرة عامة"),
            [
                labeled(
                    "تطبيق الجوال:",
                    "Flutter (Android + iOS) — GetX — Dio — Firebase FCM — "
                    "Google Sign-In — secure storage — geolocation — "
                    "وضع ليلي — دعم عربي كامل.",
                ),
                Spacer(1, 6),
                labeled(
                    "الخادم:",
                    "Laravel — REST API — Sanctum — MySQL — "
                    "Queue — FCM HTTP v1 — Middleware للأدوار.",
                ),
                Spacer(1, 6),
                labeled(
                    "لماذا هذا ال stack؟",
                    "Flutter = تطبيق واحد لمنصتين. Laravel = backend سريع "
                    "التطوير وآمن. MySQL = موثوق للتجارة. FCM = إشعارات "
                    "مجانية وفعّالة.",
                ),
            ],
            ACCENT,
        )
    )

    story.extend(
        section(
            ar("الفصل الحادي عشر: القدرة الاستيعابية"),
            [
                p(ar("خادم واحد (بداية / إطلاق):"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "• 500–2,000 مستخدم نشط يومي<br/>"
                        "• 5,000–10,000 مستخدم مسجّل<br/>"
                        "• 50–150 طلب/ساعة في الذروة<br/>"
                        "• 100–300 بائع نشط"
                    ),
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("مع توسّع (Redis + CDN + Load Balancer):"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "10,000–50,000+ مستخدم نشط يومي — "
                        "100,000+ مستخدم مسجّل — "
                        "قابل للتوسع حسب الحاجة."
                    ),
                    size=10,
                ),
            ],
        )
    )
    story.append(PageBreak())

    story.extend(
        section(
            ar("الفصل الثاني عشر: الخلاصة — ماذا يحصل العميل؟"),
            [
                labeled(
                    "المنتج النهائي:",
                    "تطبيق جوّال كامل للتجارة الإلكترونية متعددة البائعين، "
                    "مع 3 أدوار (زبون — بائع — مدير)، backend API، "
                    "قاعدة بيانات، إشعارات Push، ولوحة إدارية "
                    "مدمجة داخل التطبيق.",
                ),
                Spacer(1, 6),
                labeled(
                    "ما يميّز هذا النموذج:",
                    "workflow موافقة المنتجات — نظام اشتراكات البائعين — "
                    "تحكم إداري شامل — تجربة عربية — "
                    "طرق دفع محلية (شام كاش / COD) — "
                    "جاهز للإطلاق التجريبي.",
                ),
                Spacer(1, 6),
                labeled(
                    "قابل للتخصيص:",
                    "الاسم — الشعار — الألوان — طرق الدفع — "
                    "الفئات — سياسات الاشتراك — كلها "
                    "قابلة للتعديل حسب brand العميل.",
                ),
                Spacer(1, 8),
                p(ar("خطوات التخصيص للعميل:"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "1. اختيار اسم وشعار وهوية بصرية<br/>"
                        "2. تحديد سياسة اشتراك البائعين<br/>"
                        "3. إعداد الفئات والمحافظات<br/>"
                        "4. ربط بريد SMTP و Firebase<br/>"
                        "5. نشر على Google Play / App Store"
                    ),
                    size=10,
                ),
            ],
            ACCENT_LIGHT,
        )
    )

    story.append(Spacer(1, 20))
    story.append(
        Paragraph(
            ar("— نهاية التقرير —"),
            ParagraphStyle("end", fontName="Tahoma", fontSize=10, alignment=1, textColor=TEXT_MUTED),
        )
    )
    return story


class ConceptDoc(BaseDocTemplate):
    def __init__(self, filename: str):
        super().__init__(
            filename,
            pagesize=A4,
            rightMargin=MARGIN_R,
            leftMargin=MARGIN_L,
            topMargin=MARGIN_T,
            bottomMargin=MARGIN_B,
        )
        frame = Frame(MARGIN_L, MARGIN_B, CONTENT_W, PAGE_H - MARGIN_T - MARGIN_B, id="main")
        self.addPageTemplates([PageTemplate(id="main", frames=[frame], onPage=self._footer)])

    def _footer(self, canvas, doc):
        canvas.saveState()
        canvas.setFont("Tahoma", 8)
        canvas.setFillColor(TEXT_MUTED)
        canvas.drawCentredString(PAGE_W / 2, 10 * mm, ar(f"صفحة {doc.page}"))
        if doc.page > 1:
            canvas.setFillColor(PRIMARY)
            canvas.setFont("Tahoma-Bold", 8)
            canvas.drawRightString(PAGE_W - MARGIN_R, PAGE_H - 10 * mm, ar("عرض فكرة منصة تجارة إلكترونية"))
        canvas.restoreState()


def main() -> None:
    register_fonts()
    doc = ConceptDoc(str(OUTPUT))
    doc.build(build_story())
    print(f"Report saved: {OUTPUT}")
    print(f"Pages/size: {OUTPUT.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
