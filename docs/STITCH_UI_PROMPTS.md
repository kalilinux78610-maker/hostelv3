# HostelV3 — Stitch UI Prompts
### Complete Screen-by-Screen Prompts for All Roles

---

## STEP 1: Design System Prompt (Run this FIRST)

```
Create a design system for a mobile hostel management app called "HostelV3" for engineering colleges in India.

Design System:
- Primary color: Deep Navy Blue (#002244)
- Accent color: Vibrant Orange (#FF6B00)
- Background: Off-white (#F8F9FA)
- Card background: Pure White (#FFFFFF)
- Success: Emerald Green (#10B981)
- Error/Reject: Red (#EF4444)
- Text primary: #1A1A2E
- Text secondary: #6B7280

Typography:
- Font: Inter
- Headings: Bold, 24–28px
- Body: Regular, 14–16px
- Labels: SemiBold, 12–13px

Shape:
- Cards: 20px border radius
- Buttons: 14px border radius
- Input fields: 12px border radius

Style:
- Clean, premium, modern mobile UI
- Soft shadows on cards (0px 4px 15px rgba(0,0,0,0.06))
- Dark navy top header sections with curved bottom edges
- Orange used for highlights, badges, active states
- Glassmorphism effects on stat cards
- Smooth gradients on headers and hero sections
```

---

## STEP 2: Screen Prompts

---

### 🔐 Screen 1: Login / Welcome Screen

```
Design a premium mobile login screen for a hostel management app called "HostelV3".

Layout (top to bottom):
- Full-screen gradient background: deep navy (#002244) to dark blue (#001133)
- Top area: college building illustration or abstract geometric hostel icon in white/orange
- App name "HostelV3" in large bold white text, subtitle "Smart Hostel Management" in white/70
- Below center: a large rounded white card (glassmorphism) containing:
  - "Welcome Back" heading in navy
  - Small text: "Sign in with your college Google account"
  - Large "Continue with Google" button — white background, Google logo on left, navy text, full width, 56px height, rounded corners
  - Small text below: "Only college email addresses are allowed"
- Bottom: copyright and college name in subtle white/40 text
- Orange decorative circle/blob in top-right corner fading into background
- Style: Premium, dark, authoritative — feel like a government/university app
```

---

### 👨‍🎓 Screen 2: Student Dashboard (Home)

```
Design a mobile student dashboard for a hostel management app.

Header section (navy blue, curved bottom):
- "Good Morning, Rahul 👋" greeting in white bold
- Student info pill: "BH1 | Room 204 | CSE" in orange badge
- Top-right: bell icon with red unread badge (notifications)
- Below greeting: two stat cards side by side showing "Active Requests: 1" and "My Complaints: 2" in white glassmorphism cards with orange numbers

Main scroll area (light grey background):
Quick action grid (2x2 icon cards, white rounded cards with shadow):
  - 🏠 Apply Home Leave (navy icon)
  - 🚶 Apply Outing (orange icon)  
  - 📋 My Requests (green icon)
  - 🍽️ Mess Menu (blue icon)

"My Latest Request" card below:
  - White card with shadow
  - Shows request type, dates, current status as colored pill badge
  - Status steps: HOD ✅ → Warden ⏳ → Rector ⭕ (visual stepper)

"Today's Mess" section:
  - Three horizontal meal chips: Breakfast | Lunch | Dinner
  - One expanded meal card with a food photo, meal name, and items list

Bottom navigation bar (white, shadow):
  - Home (active, orange) | Requests | Mess | Complaints | Profile
```

---

### 📝 Screen 3: Apply Leave Form

```
Design a mobile leave application form for a college hostel app.

Header:
- Navy blue with back arrow and "Apply Leave" title in white

Content (scrollable):
- Leave type selector: two large toggle cards side by side
  - "🏠 Home Leave" (navy when selected)
  - "🚶 Outing" (selected: orange outline)
  - Each card shows description: "HOD → Warden → Rector" or "Rector only" as subtitle

- Date section (white card with shadow):
  - "From" date picker row with calendar icon
  - "To" date picker row
  - Duration chip auto-calculated: "3 Days" in orange pill

- Reason text area (white card):
  - Large multiline text field
  - Placeholder: "Describe your reason clearly..."
  - Soft border, rounded corners

- Info banner (light orange/amber background):
  - ⚠️ "Your leave fee status: PAID ✅" or "UNPAID ❌"
  - Note about fee status affecting approval

- Large navy "Submit Request" button at bottom
  - Full width, 56px height, rounded
  - Rocket icon on left

Bottom: subtle text "You will be notified at every stage of approval"
```

---

### 🔔 Screen 4: Notifications Screen

```
Design a mobile notification screen for a hostel management app.

Header:
- Navy blue, "Notifications" title in white bold
- "Mark all read" text button on right in orange

Content (white background):
- Notification list items (each is a card or list tile):
  
  Unread item style:
  - Light blue-50 background
  - Left: colored circular icon (navy for request, green for approved, red for rejected)
  - Right side: 
    - Bold title: "Warden Approved ✅"
    - Grey subtitle: "Your leave request is now pending Rector approval"
    - Time stamp: "2 hours ago" in small grey
  - Orange left border strip (3px) indicating unread

  Read item style:
  - Pure white background
  - Greyed out icon
  - Normal weight title text
  - No left border

- Notification types shown:
  1. ✅ Green circle — "Leave Request Approved" 
  2. ❌ Red circle — "Request Rejected by HOD"
  3. 📋 Navy circle — "New request submitted"
  4. 🍽️ Orange circle — "Mess menu updated for this week"
  5. 🔔 Blue circle — "Attendance marked"

Empty state (if no notifications):
  - Large grey bell icon
  - "No notifications yet"
  - Subtle grey text below
```

---

### 📋 Screen 5: My Leave Requests (Student)

```
Design a mobile screen showing a student's leave request history for a hostel app.

Header:
- Navy blue, "My Requests" in white
- Filter chips below header: "All | Pending | Approved | Rejected" horizontally scrollable

Content (light grey background, scrollable):
Each request is a white card with shadow and rounded corners:

  Pending request card:
  - Top row: "Home Leave" type label + "PENDING" orange pill badge on right
  - Dates: "Apr 5 → Apr 8, 2026" with calendar icon
  - Reason excerpt in grey italic text
  - Approval stepper:
    HOD ✅ → Warden ⏳ → Rector ⭕
    (green check, orange spinner, empty circle)
  - "View Gate Pass" button ONLY if status is Approved — orange outlined button

  Approved request card:
  - Green "APPROVED" pill badge
  - All three stepper steps green
  - "View & Download Gate Pass" — green filled button

  Rejected request card:
  - Red "REJECTED" pill badge
  - Shows which stage rejected with red X

Empty state:
  - Illustration of document with magnifier
  - "No requests yet"
  - Orange "Apply Leave" button below
```

---

### 🎫 Screen 6: Digital Gate Pass

```
Design a mobile digital gate pass screen for a hostel management app.

Background: light grey

Main card (white, large, centered, premium shadow):
  - Top: College logo placeholder + "GATE PASS" title in navy bold
  - Green "APPROVED" banner strip across top of card
  - Student avatar (circle) center top of card
  - Student name bold large
  - Branch | Room | Hostel in grey pills
  
  Info grid (2 columns):
  - Leave Type | Duration
  - From Date | To Date
  - Reason (full text)
  - Parent Contact number

  Large QR code centered (dark navy QR on white background)
  "Show this QR at the gate" instruction text below in grey

  Bottom of card: 
  - Guard scan status: "Not yet scanned" in orange or "Scanned — OUT" in green
  - Timestamp of last scan

Footer button: "Share Gate Pass" — outlined navy button
```

---

### 🍽️ Screen 7: Mess Menu (Student View)

```
Design a mobile mess menu screen for a college hostel app.

Header:
- Orange gradient header
- "Mess Menu 🍽️" title in white bold
- Week dates shown: "Week of Apr 7 – Apr 13"

Day tabs (horizontal scrollable):
  - Mon | Tue | Wed | Thu | Fri | Sat | Sun
  - Today's tab is orange with white text, others are white/grey
  - Small "Today" label appears below current day tab

Content for selected day (scrollable):
Three meal cards — each is a premium white card with shadow:

  Breakfast card:
  - Header: orange strip, "🌅 Breakfast" in orange bold, "7:30 AM – 9:00 AM" on right
  - If photo exists: large full-width food photo (180px height, cover fit)
  - Below photo: food items list in grey text with bullet points
  - e.g. "• Idli Sambar  • Poha  • Tea / Coffee"

  Lunch card:
  - Header: green strip, "☀️ Lunch" in green bold, "12:30 PM – 2:00 PM"
  - Food photo + items list same as above in green theme

  Dinner card:
  - Header: navy strip, "🌙 Dinner" in navy bold, "7:30 PM – 9:00 PM"
  - Food photo + items list in navy theme

  "Menu not set yet" state:
  - Dashed border card, centered grey fork icon, "Menu not set for this day"
```

---

### 📩 Screen 8: File Complaint

```
Design a mobile complaint filing screen for a hostel management app.

Header:
- Navy, "File a Complaint" in white, back arrow

Content:
- Category selector (horizontal scrollable chips):
  "Maintenance | Electricity | Water | Food | Security | Other"
  Selected chip in navy-fill with white text

- Complaint description card (white, shadow):
  - Label: "Describe the issue"
  - Large multiline text field, rounded, soft border
  - Placeholder: "Explain the problem in detail..."
  - Character counter bottom right

- Photo attachment section (white card):
  - "Attach a Photo (optional)" label
  - Dashed border upload area with camera icon + "Tap to add photo"
  - If photo selected: thumbnail preview with X remove button

- Location field:
  - "Location / Room / Area" text input with location pin icon

- Privacy note:
  - 🔒 "Your complaint is submitted confidentially to hostel administration"

- "Submit Complaint" button — navy, full width, rounded
```

---

### 👨‍💼 Screen 9: HOD Dashboard

```
Design a mobile HOD (Head of Department) dashboard for a college hostel management app.

Header (navy blue, curved bottom):
- "HOD Dashboard" in white bold
- Department name: "Computer Science Engineering" in orange
- Small stat: "7 Pending Reviews" badge in orange pill

Pending requests list (main content):
Each request is a white card with shadow:
  - Left: Student avatar circle with initials
  - Student name bold, "CSE | 3rd Year" in grey
  - Request type pill: "Home Leave" in navy or "Outing" in orange
  - Date range: Apr 5 → Apr 8
  - Urgency badge if leaving within 24 hrs: blinking red "URGENT" badge
  - Reason excerpt in grey
  - Two buttons at bottom of card: "REJECT" (red outline) | "APPROVE" (navy filled)

Empty state:
  - Green check illustration
  - "All caught up! No pending requests."

Bottom navigation:
  - Pending | History | Profile
```

---

### 🏠 Screen 10: Warden Dashboard

```
Design a mobile Warden dashboard for a hostel management app.

Header (navy blue, curved bottom, large):
- "Welcome, Warden" in white
- Hostel name: "Boys Hostel 1" in orange badge  
- Two large stat cards (glassmorphism / transparent white):
  - "PENDING: 12" with orange clock icon
  - "OUT NOW: 8" with blue walking person icon
- Toggle: [Pending Requests] [Out Now] — orange active underline

Pending list tab:
List of white cards per department/branch:
Each card shows:
  - Branch name: "Computer Science | B.Tech"
  - Count: "3 pending" in orange pill
  - Tap to open list → full student cards with approve/reject

Out Now tab:
  - List of students currently outside
  - Each item: Name, room, "Out since 2:30 PM Apr 4"
  - Expected return date

Bottom navigation:
  - Home | Complaints | Profile
```

---

### 🏛️ Screen 11: Rector Dashboard

```
Design a mobile Rector dashboard for a premium hostel management system.

Header (large, navy, curved bottom, premium):
- "Rector Dashboard" bold white
- Institution name subtitle in white/70
- Three large stat cards in glassmorphism style:
  - PENDING: 5 (orange)
  - OUT NOW: 23 (blue)
  - RETURNED TODAY: 41 (green)

Pending requests (main tab):
Large white cards per student:
  - Student avatar + name + email
  - "Home Leave | Apr 5 – Apr 8" with calendar
  - HOD ✅ Warden ✅ → Rector ⏳ stepper below
  - Reason box (collapsible)
  - Parent contact with phone icon (tappable)
  - REJECT (red outline) | APPROVE (green filled) full-width buttons

Out Now tab:
  - Table-style list with student name, hostel, departure time
  - Search bar at top

Navigation tabs at top (not bottom):
  Pending | Out Now | History | Students | Reports
```

---

### 🔍 Screen 12: Guard QR Scanner

```
Design a mobile QR scanner screen for a gate guard at a college hostel.

Full screen layout:
- Dark background
- Center: large camera viewfinder with rounded corner guides (like scanner frame)
- Orange corner highlights on scanner frame
- "Scan student gate pass QR" instruction text in white below frame
- Scanning animation: orange horizontal line sweeping up/down

After successful scan — slide up bottom sheet:
  - Green header: "✅ Valid Gate Pass"
  - Student photo + name + room
  - Leave type | Dates
  - Status pill: "APPROVED — Ready to Exit" in green
  - Two action buttons:
    - "Mark as OUT 🚶" — large green button
    - "Cancel" — grey text button

Invalid QR bottom sheet:
  - Red header "❌ Invalid or Expired Pass"
  - Error message
  - "Try Again" button

Top of screen:
  - Small "Recent Scans" button (top right)
  - Flashlight toggle icon
```

---

### 🍳 Screen 13: Mess Manager Dashboard

```
Design a mobile mess manager dashboard for a hostel app.

Header (navy blue):
- "Mess Manager" title in white
- "Main Hostel Mess" subtitle in orange

Bottom navigation: Menu Editor | Stock | Profile

Menu Editor tab (default):
- Day tabs: Mon Tue Wed Thu Fri Sat Sun (horizontally scrollable, orange active)
- For selected day, three tall meal editor cards:

  Each meal card (white, large, shadow, rounded 20px):
  - Header strip (colored: orange/green/navy per meal):
    - Meal icon + name on left ("Breakfast")
    - "Add Photo" / "Change Photo" button on right (outlined, colored)
  - If photo uploaded: full-width food photo (160px) below header
  - If no photo: dashed area with camera icon + "Tap to add breakfast photo"
  - Text area below: rounded multiline input "Enter items..."
  - Placeholder with example: "Idli, Sambar, Chutney, Tea"

- "Save Menu to Cloud ☁️" large navy button at bottom

Profile tab:
  - Avatar circle (editable)
  - Name and email display
  - Editable: Mess Name, Phone Number
  - "Save Changes" navy button
  - "Sign Out" red outlined button at bottom
```

---

### 🔧 Screen 14: Admin Dashboard

```
Design a mobile admin dashboard for a comprehensive hostel management system.

Header (navy gradient):
- "Admin Panel" in white bold
- "Full System Access" in orange
- Quick stats row: Students | Requests Today | Active Complaints | Staff Count

Main grid (2x2 large action tiles, white cards with shadow):
Row 1:
  - 👥 Student Directory (navy icon)
  - 📊 Reports & Analytics (orange icon)
Row 2:
  - 📥 Bulk Import Students (green icon)
  - 👨‍💼 Staff Management (purple icon)
Row 3:
  - 🏠 Room Availability (teal icon)  
  - 🍽️ Mess Management (red/orange icon)

Activity Feed section below:
- "Recent Activity" heading
- Live feed list: each item shows action, who did it, how long ago
  e.g. "Rector approved Rahul's leave • 5 min ago"
  e.g. "New complaint filed in BH1 • 12 min ago"
  Each item has a colored left dot (green approved, red rejected, orange pending)

Bottom navigation:
  - Home | Students | Reports | Staff | Profile
```

---

## Usage Instructions

1. Go to **Stitch** (stitch.withgoogle.com)
2. Create a new project called "HostelV3"
3. **First run the Design System prompt** (Step 1 above)
4. Then create each screen using the prompts in Step 2
5. Generate variants for any screen you want multiple options for
6. Export as Flutter code or use as design reference

---

## Tips for Best Results in Stitch

- Set **device type = Mobile** for all screens
- Use **Gemini 3.1 Pro** model for best quality
- After generating, use **Edit Screen** to fine-tune specific elements
- Generate 2-3 variants of the Student Dashboard and Rector Dashboard — those are the most important
- Ask Stitch to "make it more premium" or "add more visual hierarchy" if the first result is too plain
