#!/usr/bin/env python3
"""Generate ZADAK technical report PDF matching reference lecture-summary layout."""

from __future__ import annotations

import os
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
    Image,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
)
from reportlab.platypus.flowables import Flowable

# ── paths ──────────────────────────────────────────────────────────────────
LOGO = Path(r"C:\Users\pc\Desktop\zadak-app-icon-no-watermark.png")
OUTPUT = Path(r"C:\Users\pc\Desktop\ZADAK-Report.pdf")
FONT_REG = r"C:\Windows\Fonts\tahoma.ttf"
FONT_BOLD = r"C:\Windows\Fonts\tahomabd.ttf"

# ── ZADAK brand palette (from app_colors.dart + logo) ─────────────────────
NAVY = colors.HexColor("#153B6D")
DEEP_PURPLE = colors.HexColor("#2E3192")
DARK_INDIGO = colors.HexColor("#310047")
VIBRANT_BLUE = colors.HexColor("#0072FF")
ACCENT_CYAN = colors.HexColor("#00AEEF")
TEXT_PRIMARY = colors.HexColor("#1A1A2E")
TEXT_SECONDARY = colors.HexColor("#5A6070")
TEXT_MUTED = colors.HexColor("#8E8E93")
BG_LIGHT = colors.HexColor("#F8F9FC")
BOX_BG = colors.HexColor("#F0F4FC")
BOX_BORDER = colors.HexColor("#D8E2F4")
HIGHLIGHT_BG = colors.HexColor("#E8F0FF")
DIVIDER = colors.HexColor("#153B6D")

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
    """Light rounded content box with right accent bar (RTL style)."""

    def __init__(
        self,
        content: list[Flowable],
        width: float,
        accent: colors.Color = NAVY,
        bg: colors.Color = BOX_BG,
        pad: float = 10,
        radius: float = 8,
        bar_w: float = 4,
    ):
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
        c.roundRect(
            self.width - self.bar_w - 2,
            2,
            self.bar_w,
            self._height - 4,
            2,
            fill=1,
            stroke=0,
        )
        for item in self.content:
            item.drawOn(c, getattr(item, "_box_x", self.pad), self._height - getattr(item, "_box_y", self.pad) - item.height)
        c.restoreState()


class SectionTitle(Flowable):
    def __init__(self, title: str, width: float, accent: colors.Color = NAVY):
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
        c.setFillColor(NAVY)
        c.roundRect(x, 0, self.badge_w, self.badge_h, self.badge_h / 2, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont("Tahoma-Bold", 9)
        c.drawCentredString(x + self.badge_w / 2, 6, self.text)
        c.restoreState()


class HorizontalRule(Flowable):
    def __init__(self, width: float, color: colors.Color = DIVIDER, thickness: float = 1.2):
        super().__init__()
        self.width = width
        self.color = color
        self.thickness = thickness
        self._height = 8

    def wrap(self, aW, aH):
        return self.width, self._height

    def draw(self):
        c = self.canv
        c.saveState()
        c.setStrokeColor(self.color)
        c.setLineWidth(self.thickness)
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
        c.setFillColor(NAVY)
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
    """Bold Arabic label + body; reshape each part separately so HTML stays valid."""
    return p(f"<b>{ar(label)}</b> {ar(body)}", size=size)


def bullet_block(items: list[str], size: float = 10) -> list[Flowable]:
    lines = []
    for item in items:
        lines.append(p(f"• {item}", size=size))
        lines.append(Spacer(1, 2))
    return lines


def content_box(paragraphs: list[Flowable], accent: colors.Color = NAVY) -> RoundedBox:
    return RoundedBox(paragraphs, CONTENT_W, accent=accent)


def section(title: str, paragraphs: list[Flowable], accent: colors.Color = NAVY) -> list[Flowable]:
    return [
        Spacer(1, 8),
        SectionTitle(title, CONTENT_W, accent),
        Spacer(1, 4),
        content_box(paragraphs, accent),
    ]


def build_story() -> list:
    today = date.today().strftime("%d / %m / %Y")
    story: list = []

    # ── Cover ──────────────────────────────────────────────────────────────
    story.append(PillBadge(ar("تقرير فني شامل"), width=130))
    story.append(Spacer(1, 10))

    if LOGO.exists():
        logo = Image(str(LOGO), width=52 * mm, height=52 * mm)
        logo.hAlign = "CENTER"
        story.append(logo)
        story.append(Spacer(1, 8))

    story.append(p(ar("ZADAK"), size=22, bold=True, color=TEXT_PRIMARY))
    story[-1].style.alignment = 1  # center hack via new paragraph
    story.append(Spacer(1, 2))
    cover_title = Paragraph(
        ar("تطبيق زاداك للتجارة الإلكترونية"),
        ParagraphStyle(
            "cover_title",
            fontName="Tahoma-Bold",
            fontSize=18,
            leading=24,
            alignment=1,
            textColor=TEXT_PRIMARY,
        ),
    )
    story.append(cover_title)
    story.append(Spacer(1, 4))
    story.append(
        Paragraph(
            ar("تحليل شامل للمنصة — الميزات — الأدوات — القدرة الاستيعابية"),
            ParagraphStyle(
                "cover_sub",
                fontName="Tahoma",
                fontSize=12,
                leading=18,
                alignment=1,
                textColor=VIBRANT_BLUE,
            ),
        )
    )
    story.append(Spacer(1, 6))
    story.append(
        Paragraph(
            ar(f"إعداد: فريق تطوير ZADAK | {today}"),
            ParagraphStyle(
                "cover_meta",
                fontName="Tahoma",
                fontSize=9,
                leading=12,
                alignment=1,
                textColor=TEXT_MUTED,
            ),
        )
    )
    story.append(Spacer(1, 10))
    story.append(HorizontalRule(CONTENT_W))
    story.append(Spacer(1, 10))

    toc_items = [
        ar("1. نظرة عامة عن التطبيق"),
        ar("2. الميزات الرئيسية"),
        ar("3. أنواع الحسابات وصلاحياتها"),
        ar("4. تحليل تفصيلي للميزات"),
        ar("5. الأدوات والتقنيات المستخدمة"),
        ar("6. القدرة الاستيعابية وعدد المستخدمين"),
        ar("7. الأمان والبنية التحتية"),
        ar("8. التوصيات والخلاصة"),
    ]
    story.append(TocBox(ar("فهرس المحتويات"), toc_items, CONTENT_W))
    story.append(PageBreak())

    # ── 1. Overview ────────────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل الأول: نظرة عامة عن التطبيق"),
            [
                labeled(
                    "تعريف ZADAK:",
                    "منصة تجارة إلكترونية متكاملة تربط بين المستهلكين (الزبائن) "
                    "والتجّار (البائعين) تحت إشراف لوحة تحكم إدارية. يوفّر التطبيق "
                    "تجربة تسوق عربية كاملة من تصفّح المنتجات وإضافتها للسلة "
                    "وحتى الدفع والتوصيل وتتبّع الطلبات.",
                ),
                Spacer(1, 6),
                labeled(
                    "الهدف:",
                    "تمكين التجّار من عرض منتجاتهم ضمن اشتراك منظّم، "
                    "مع منح الإدارة صلاحيات الموافقة على المنتجات وإدارة الطلبات "
                    "والمبيعات والكوبونات والعروض، بينما يحصل الزبون على واجهة "
                    "سلسة للشراء والمتابعة.",
                ),
                Spacer(1, 6),
                labeled(
                    "البنية:",
                    "تطبيق جوّال Flutter (Android / iOS) يتصل بـ API REST "
                    "مبني على Laravel 8 وقاعدة بيانات MySQL، مع إشعارات فورية "
                    "عبر Firebase Cloud Messaging.",
                ),
            ],
            NAVY,
        )
    )

    # ── 2. Features ────────────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل الثاني: الميزات الرئيسية"),
            bullet_block(
                [
                    ar("تسجيل دخول بالبريد أو Google — مع تحقق OTP للحسابات الجديدة"),
                    ar("تصفّح الفئات والمنتجات — بحث — فلترة — تفاصيل المنتج والمتجر"),
                    ar("سلة مشتريات — كوبونات خصم — طرق دفع (شام كاش / الدفع عند الاستلام)"),
                    ar("إدارة الطلبات — تتبّع التوصيل — تأكيد الاستلام"),
                    ar("المفضّلة — الإشعارات — الملف الشخصي — الوضع الليلي واللغة"),
                    ar("لوحة البائع: إضافة/تعديل/حذف منتجات (بموافقة الإدارة) + اشتراكات"),
                    ar("لوحة الإدارة: طلبات — مبيعات — مستخدمين — بائعين — فئات — شرائح رئيسية"),
                    ar("كوبونات — بث إشعارات — اشتراكات توصيل مجاني — موافقة المنتجات"),
                    ar("تذكير اشتراك البائع قبل 3 أيام من الانتهاء (داخل التطبيق + FCM)"),
                    ar("منتجات مميّزة متناوبة — شرائح الصفحة الرئيسية — توصيل مجاني للمشتركين"),
                ],
                size=10,
            ),
            DEEP_PURPLE,
        )
    )
    story.append(PageBreak())

    # ── 3. Account types ───────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل الثالث: أنواع الحسابات وصلاحياتها"),
            [
                p(ar("① حساب الزبون (Customer)"), size=11, bold=True, color=VIBRANT_BLUE),
                Spacer(1, 3),
                p(
                    ar(
                        "ينشئ حسابه بنفسه عبر التسجيل أو Google. يتصفّح الكatalog، يضيف للسلة، "
                        "يطبّق كوبونات، يُنشئ طلبات، يتابع التوصيل، يؤكّد الاستلام، يدير ملفه "
                        "وكلمة المرور (نسيان/تغيير). المفضّلة محلية على الجهاز."
                    ),
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("② حساب البائع (Seller)"), size=11, bold=True, color=DEEP_PURPLE),
                Spacer(1, 3),
                labeled(
                    "المدير فقط ينشئ الحساب:",
                    "لا يمكن للبائع التسجيل الذاتي. يعرض منتجاته بعد موافقة الإدارة، "
                    "يطلب تعديل/حذف منتج، يتابع اشتراكه (نشط/منتهٍ). "
                    "قيود: لا يغيّر البريد/الهاتف — لا يستعيد كلمة المرور — "
                    "المدير فقط يعيد تعيين كلمة المرور.",
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("③ حساب المدير (Admin)"), size=11, bold=True, color=DARK_INDIGO),
                Spacer(1, 3),
                p(
                    ar(
                        "صلاحيات كاملة: إدارة الطلبات (موافقة دفع — رفض — وقت توصيل — وصول)، "
                        "تقارير المبيعات، المستخدمين، إنشاء/تجديد/حظر/إلغاء البائعين، "
                        "الفئات والتصنيفات الفرعية، شرائح الصفحة الرئيسية، الكوبونات، "
                        "اشتراكات التوصيل المجاني، الموافقة على طلبات المنتجات، "
                        "وبث إشعارات لجميع المستخدمين."
                    ),
                    size=10,
                ),
            ],
            NAVY,
        )
    )

    # ── 4. Detailed analysis ───────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل الرابع: تحليل تفصيلي للميزات"),
            [
                p(ar("المصادقة والأمان"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "Sanctum tokens — OTP للتسجيل ونسيان كلمة المرور — Google Sign-In — "
                        "تخزين آمن للتوكن (flutter_secure_storage) — middleware seller/admin "
                        "على مسارات API."
                    ),
                    size=9.8,
                ),
                Spacer(1, 6),
                p(ar("التسوّق والطلبات"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "عرض منتجات مع cache 300 ثانية — pagination للطلبات — "
                        "validate كوبون — Sham Cash + COD — حالات طلب متعددة "
                        "(pending → paid → processing → shipped → delivered)."
                    ),
                    size=9.8,
                ),
                Spacer(1, 6),
                p(ar("إدارة البائعين والمنتجات"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "workflow: البائع يُرسل → الإدارة توافق/ترفض → المنتج يظهر في الكatalog. "
                        "اشتراك البائع يحدّد إمكانية البيع — تذكير قبل 3 أيام. "
                        "اشتراك التوصيل المجاني يربط منتجات بائع محدّد."
                    ),
                    size=9.8,
                ),
                Spacer(1, 6),
                p(ar("الإشعارات"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "FCM push + إشعارات داخل التطبيق — بث جماعي بchunks من 100 — "
                        "queue database للإرسال غير المتزامن — unread count."
                    ),
                    size=9.8,
                ),
            ],
            DEEP_PURPLE,
        )
    )
    story.append(PageBreak())

    # Customer deep dive
    story.extend(
        section(
            ar("تحليل حساب الزبون — تفصيل الشاشات"),
            bullet_block(
                [
                    ar("Splash + Onboarding — أول تشغيل"),
                    ar("Login / Register / OTP / Google / Forgot Password"),
                    ar("الرئيسية: شرائح — فئات — منتجات مميّزة — توصيل مجاني"),
                    ar("بحث + فلتر + نتائج + تفاصيل منتج + صفحة متجر"),
                    ar("سلة → عنوان → دفع → نجاح → طلباتي → تتبّع → تأكيد استلام"),
                    ar("إشعارات — مفضّلة — ملف شخصي — مظهر — لغة — مساعدة"),
                ],
                size=9.8,
            ),
            VIBRANT_BLUE,
        )
    )

    story.extend(
        section(
            ar("تحليل حساب البائع — تفصيل الشاشات"),
            bullet_block(
                [
                    ar("تسجيل دخول بحساب أنشأه المدير"),
                    ar("منتجاتي: قائمة — إضافة — طلب تعديل — طلب حذف"),
                    ar("اشتراكاتي: حالة الاشتراك — تنبيه قرب الانتهاء"),
                    ar("الملف الشخصي: الاسم فقط (البريد/الهاتف للقراءة)"),
                    ar("لا وصول لـ: forgot password — change password — إنشاء حساب"),
                ],
                size=9.8,
            ),
            DEEP_PURPLE,
        )
    )

    story.extend(
        section(
            ar("تحليل حساب المدير — تفصيل الشاشات"),
            bullet_block(
                [
                    ar("الطلبات: عرض — موافقة دفع — رفض — وقت توصيل — إشعار — وصول"),
                    ar("المبيعات: تقارير وإحصائيات"),
                    ar("المستخدمون + البائعون: إنشاء — تجديد — حظر — إلغاء — reset password"),
                    ar("الفئات + التصنيفات الفرعية — CRUD كامل"),
                    ar("شرائح الرئيسية — كوبونات — اشتراكات توصيل مجاني"),
                    ar("موافقة المنتجات (submissions) — بث إشعار عام"),
                ],
                size=9.8,
            ),
            DARK_INDIGO,
        )
    )
    story.append(PageBreak())

    # ── 5. Tools ───────────────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل الخامس: الأدوات والتقنيات المستخدمة"),
            [
                p(ar("تطبيق الجوّال (Flutter)"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "Flutter 3.11+ — GetX (state/routing) — Dio (HTTP) — "
                        "Firebase Core + FCM — flutter_secure_storage — google_sign_in — "
                        "geolocator/geocoding — file_picker — pdf/printing — "
                        "flutter_local_notifications — permission_handler — google_fonts"
                    ),
                    size=9.5,
                ),
                Spacer(1, 8),
                p(ar("الخادم (Backend)"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "Laravel 8 — PHP — Laravel Sanctum — MySQL — Queue (database driver) — "
                        "FCM HTTP v1 — REST API — Middleware (auth/seller/admin)"
                    ),
                    size=9.5,
                ),
                Spacer(1, 8),
                p(ar("أدوات التطوير والبناء"), size=10.5, bold=True),
                Spacer(1, 2),
                p(
                    ar(
                        "Android Studio — VS Code/Cursor — Git — Python scripts "
                        "(أيقونات adaptive — إزالة watermark — توليد التقرير) — "
                        "OpenCV — PyMuPDF — ReportLab"
                    ),
                    size=9.5,
                ),
            ],
            ACCENT_CYAN,
        )
    )

    # ── 6. Capacity ────────────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل السادس: القدرة الاستيعابية وعدد المستخدمين"),
            [
                p(ar("الوضع الحالي (خادم واحد — تطوير/إنتاج صغير):"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "• 500–2,000 مستخدم نشط يومي (DAU) بسلاسة<br/>"
                        "• 5,000–10,000 مستخدم مسجّل إجمالي<br/>"
                        "• 50–150 طلب/ساعة في أوقات الذروة<br/>"
                        "• 100–300 بائع نشط مع اشتراكات سارية"
                    ),
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("مع تحسينات الإنتاج:"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "Redis cache + queue worker + CDN للصور + pagination كامل للمنتجات → "
                        "10,000–30,000 DAU و100,000+ مستخدم مسجّل.<br/>"
                        "Load balancer + read replicas → 50,000+ DAU."
                    ),
                    size=10,
                ),
                Spacer(1, 8),
                p(ar("عوامل الضغط الحالية:"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "قائمة المنتجات بدون pagination كامل — تقرير المبيعات يحمّل كل العناصر — "
                        "يتطلّب تشغيل queue:work و scheduler — FCM broadcast بchunks 100."
                    ),
                    size=9.8,
                    color=TEXT_SECONDARY,
                ),
            ],
            NAVY,
        )
    )

    # ── 7. Security & infra ────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل السابع: الأمان والبنية التحتية"),
            bullet_block(
                [
                    ar("HTTPS في الإنتاج — Sanctum bearer tokens — role middleware"),
                    ar("OTP rate limiting — hashed passwords (bcrypt)"),
                    ar("FCM device tokens — إشعارات مرتبطة بالمستخدم"),
                    ar("Catalog cache 300s — تقليل ضغط DB"),
                    ar("Database queue — إرسال push غير متزامن"),
                    ar("فصل صلاحيات seller/admin على مستوى API"),
                ],
                size=9.8,
            ),
            DEEP_PURPLE,
        )
    )
    story.append(PageBreak())

    # ── 8. Conclusion ──────────────────────────────────────────────────────
    story.extend(
        section(
            ar("الفصل الثامن: التوصيات والخلاصة"),
            [
                labeled(
                    "الخلاصة:",
                    "ZADAK منصة تجارة إلكترونية متكاملة بثلاثة أدوار "
                    "(زبون — بائع — مدير) مع workflow واضح للمنتجات والاشتراكات والطلبات. "
                    "التطبيق جاهز للإطلاق التجريبي على نطاق متوسط مع خادم واحد.",
                ),
                Spacer(1, 8),
                p(ar("توصيات:"), size=10.5, bold=True),
                Spacer(1, 4),
                p(
                    ar(
                        "1. pagination للمنتجات في API<br/>"
                        "2. Redis + queue worker دائم<br/>"
                        "3. CDN لتخزين صور المنتجات<br/>"
                        "4. monitoring (logs + uptime)<br/>"
                        "5. backup يومي لـ MySQL"
                    ),
                    size=10,
                ),
            ],
            VIBRANT_BLUE,
        )
    )

    story.append(Spacer(1, 20))
    story.append(
        Paragraph(
            ar("— نهاية التقرير —"),
            ParagraphStyle(
                "end",
                fontName="Tahoma",
                fontSize=10,
                alignment=1,
                textColor=TEXT_MUTED,
            ),
        )
    )

    return story


class ZadakDoc(BaseDocTemplate):
    def __init__(self, filename: str):
        super().__init__(
            filename,
            pagesize=A4,
            rightMargin=MARGIN_R,
            leftMargin=MARGIN_L,
            topMargin=MARGIN_T,
            bottomMargin=MARGIN_B,
        )
        frame = Frame(
            MARGIN_L,
            MARGIN_B,
            CONTENT_W,
            PAGE_H - MARGIN_T - MARGIN_B,
            id="main",
        )
        self.addPageTemplates([PageTemplate(id="main", frames=[frame], onPage=self._footer)])

    def _footer(self, canvas, doc):
        canvas.saveState()
        canvas.setFont("Tahoma", 8)
        canvas.setFillColor(TEXT_MUTED)
        page_num = ar(f"صفحة {doc.page}")
        canvas.drawCentredString(PAGE_W / 2, 10 * mm, page_num)
        if doc.page > 1:
            canvas.setFillColor(NAVY)
            canvas.setFont("Tahoma-Bold", 8)
            canvas.drawRightString(PAGE_W - MARGIN_R, PAGE_H - 10 * mm, ar("ZADAK — تقرير فني"))
        canvas.restoreState()


def main() -> None:
    register_fonts()
    doc = ZadakDoc(str(OUTPUT))
    doc.build(build_story())
    print(f"Report saved: {OUTPUT}")
    print(f"Size: {OUTPUT.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
