# Design System

## Color & Theme Specification

본 문서는 Dangple 프로젝트의 UI 일관성과 접근성을 유지하기 위한 **Color Design System**을 정의한다.

모든 UI 구현은 본 문서의 컬러 토큰을 기준으로 하며, 임의의 색상 사용을 금지한다.

---

## 1. Color Principles

### 1.1 Design Goals

* UI 전반의 **시각적 일관성 유지**
* Light / Dark mode 완전 대응
* 의미 기반 컬러 사용 (색 = 역할)
* 접근성(가독성, 대비) 확보

### 1.2 Usage Rules

* 컬러는 **Hex 값 직접 사용 금지**
* 반드시 **정의된 토큰 이름**을 사용
* 색상 선택이 아닌 **역할 선택**으로 UI 구성

---

## 2. Brand & Semantic Colors

### 2.1 Primary Colors

| Token      | Description      | Hex       | Opacity |
| ---------- | ---------------- | --------- | ------- |
| `main`     | Primary / Active | `#67A4FF` | 100%    |
| `main_dis` | Primary Disabled | `#67A4FF` | 50%     |
| `sub`      | Secondary Accent | `#297FFF` | 100%    |

### 2.2 Semantic Colors

| Token     | Description                | Hex       |
| --------- | -------------------------- | --------- |
| `green`   | Success / Positive         | `#00CC66` |
| `red`     | Error / Warning / Negative | `#FF5757` |
| `red_sub` | Error Sub / Background     | `#FF5757` |

---

## 3. Base Colors

| Token        | Description              | Hex       |
| ------------ | ------------------------ | --------- |
| `black`      | Absolute Black           | `#000000` |
| `white`      | Absolute White           | `#FFFFFF` |
| `toastpopup` | Toast / Popup Background | `#555555` |

---

## 4. Light Mode Colors

### 4.1 Text Colors (Light)

| Token                 | Usage           | Hex       |
| --------------------- | --------------- | --------- |
| `fontPrimary_light`   | Primary Text    | `#262626` |
| `fontSecondary_light` | Secondary Text  | `#333333` |
| `fontTertiary_light`  | Tertiary Text   | `#555555` |
| `fontGuide_light`     | Guide / Hint    | `#777777` |
| `fontHide_light`      | Hidden / Subtle | `#999999` |
| `fontDisabled_light`  | Disabled Text   | `#B0B0B0` |

### 4.2 Background & Border (Light)

| Token              | Usage            | Hex       |
| ------------------ | ---------------- | --------- |
| `bgBasic_light`    | App Background   | `#FFFFFF` |
| `bgContents_light` | Card / Section   | `#F4F4F4` |
| `bgBorder_light`   | Divider / Border | `#D9D9D9` |
| `bgDisabled_light` | Disabled BG      | `#CCCCCC` |

---

## 5. Dark Mode Colors

### 5.1 Text Colors (Dark)

| Token                | Usage           | Hex       |
| -------------------- | --------------- | --------- |
| `fontPrimary_dark`   | Primary Text    | `#FFFFFF` |
| `fontSecondary_dark` | Secondary Text  | `#EBEEF5` |
| `fontTertiary_dark`  | Tertiary Text   | `#DEE3EE` |
| `fontGuide_dark`     | Guide / Hint    | `#C7CDDB` |
| `fontHide_dark`      | Hidden / Subtle | `#AFB5C3` |
| `fontDisabled_dark`  | Disabled Text   | `#818897` |

### 5.2 Background & Border (Dark)

| Token             | Usage            | Hex       |
| ----------------- | ---------------- | --------- |
| `bgBasic_dark`    | App Background   | `#15171A` |
| `bgContents_dark` | Card / Section   | `#21252A` |
| `bgBorder_dark`   | Divider / Border | `#575C68` |
| `bgDisabled_dark` | Disabled BG      | `#6B717F` |

---

## 6. Accessibility & Contrast Rules

* Primary text는 항상 `fontPrimary` 계열 사용
* Disabled 상태는 반드시 `fontDisabled`, `bgDisabled` 사용
* Semantic color(`red`, `green`)는 **텍스트 단독 사용 금지**

  * 반드시 아이콘, 라벨, 문맥과 함께 사용

---

## 7. Implementation Rules (Mandatory)

### 7.1 Forbidden

* Hex 직접 사용 ❌
* 임의 Gray 생성 ❌
* opacity 임의 조절 ❌

### 7.2 Required

* Token 이름으로만 참조
* Light / Dark mode 자동 분기
* 컴포넌트별 컬러 역할 고정

---

## 8. Example Usage

### Button (Primary)

* Background: `main`
* Text: `white`
* Disabled BG: `main_dis`
* Disabled Text: `fontDisabled`

### Text

* Title: `fontPrimary`
* Description: `fontSecondary`
* Hint: `fontGuide`

---

## 9. Final Principle

> **UI는 선택이 아니라 규칙이다.**
> 이 Design System은 미적 판단을 줄이고,
> 일관성과 확장성을 확보하기 위한 기준점이다.
