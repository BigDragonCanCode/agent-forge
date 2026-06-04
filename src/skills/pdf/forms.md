**CRITICAL: MUST do steps in order. No skip ahead write code.**

If need fill PDF form, first check if PDF have fillable fields. Run from this file dir:
 `python scripts/check_fillable_fields <file.pdf>`, then go to "Fillable fields" or "Non-fillable fields" and do that path.

# Fillable fields
If PDF have fillable fields:
- Run from this file dir: `python scripts/extract_form_field_info.py <input.pdf> <field_info.json>`. This make JSON list of fields in this format:
```
[
  {
    "field_id": (unique ID for the field),
    "page": (page number, 1-based),
    "rect": ([left, bottom, right, top] bounding box in PDF coordinates, y=0 is the bottom of the page),
    "type": ("text", "checkbox", "radio_group", or "choice"),
  },
  // Checkboxes have "checked_value" and "unchecked_value" properties:
  {
    "field_id": (unique ID for the field),
    "page": (page number, 1-based),
    "type": "checkbox",
    "checked_value": (Set the field to this value to check the checkbox),
    "unchecked_value": (Set the field to this value to uncheck the checkbox),
  },
  // Radio groups have a "radio_options" list with the possible choices.
  {
    "field_id": (unique ID for the field),
    "page": (page number, 1-based),
    "type": "radio_group",
    "radio_options": [
      {
        "value": (set the field to this value to select this radio option),
        "rect": (bounding box for the radio button for this option)
      },
      // Other radio options
    ]
  },
  // Multiple choice fields have a "choice_options" list with the possible choices:
  {
    "field_id": (unique ID for the field),
    "page": (page number, 1-based),
    "type": "choice",
    "choice_options": [
      {
        "value": (set the field to this value to select this option),
        "text": (display text of the option)
      },
      // Other choice options
    ],
  }
]
```
- Convert PDF to PNGs, one image per page, with this script from this file dir:
`python scripts/convert_pdf_to_images.py <file.pdf> <output_directory>`
Then inspect images to learn each field purpose. Must convert bounding box PDF coords to image coords.
- Make a `field_values.json` file in this format with values for each field:
```
[
  {
    "field_id": "last_name", // Must match the field_id from `extract_form_field_info.py`
    "description": "The user's last name",
    "page": 1, // Must match the "page" value in field_info.json
    "value": "Simpson"
  },
  {
    "field_id": "Checkbox12",
    "description": "Checkbox to be checked if the user is 18 or over",
    "page": 1,
    "value": "/On" // If this is a checkbox, use its "checked_value" value to check it. If it's a radio button group, use one of the "value" values in "radio_options".
  },
  // more fields
]
```
- Run `fill_fillable_fields.py` from this file dir to make filled PDF:
`python scripts/fill_fillable_fields.py <input pdf> <field_values.json> <output pdf>`
This script checks field IDs and values. If it prints errors, fix fields and try again.

# Non-fillable fields
If PDF no fillable fields, add text annotations. First try extract coords from PDF structure for better accuracy. If that fail, use visual estimate.

## Step 1: Try Structure Extraction First

Run this script to extract text labels, lines, and checkboxes with exact PDF coords:
`python scripts/extract_form_structure.py <input.pdf> form_structure.json`

This makes JSON with:
- **labels**: Every text element with exact coords (x0, top, x1, bottom in PDF points)
- **lines**: Horizontal lines that mark row boundaries
- **checkboxes**: Small square rectangles that are checkboxes (with center coords)
- **row_boundaries**: Row top/bottom positions computed from horizontal lines

**Check results**: If `form_structure.json` has useful labels matching form fields, use **Approach A: Structure-Based Coordinates**. If PDF is scanned/image-based and has few or no labels, use **Approach B: Visual Estimation**.

---

## Approach A: Structure-Based Coordinates (Preferred)

Use when `extract_form_structure.py` found text labels in PDF.

### A.1: Analyze the Structure

Read form_structure.json and find:

1. **Label groups**: Nearby text elements that make one label, like "Last" + "Name"
2. **Row structure**: Labels with similar `top` values in same row
3. **Field columns**: Entry areas start after label ends (x0 = label.x1 + gap)
4. **Checkboxes**: Use checkbox coords direct from structure

**Coordinate system**: PDF coords where y=0 at TOP of page, y grows downward.

### A.2: Check for Missing Elements

Structure extraction may miss some form elements. Common cases:
- **Circular checkboxes**: Only square rectangles get detected as checkboxes
- **Complex graphics**: Decorative elements or non-standard form controls
- **Faded or light-colored elements**: May not get extracted

If PDF images show fields not in form_structure.json, use **visual analysis** for those fields only. See "Hybrid Approach" below.

### A.3: Create fields.json with PDF Coordinates

For each field, compute entry coords from extracted structure:

**Text fields:**
- entry x0 = label x1 + 5 (small gap after label)
- entry x1 = next label's x0, or row boundary
- entry top = same as label top
- entry bottom = row boundary line below, or label bottom + row_height

**Checkboxes:**
- Use checkbox rectangle coords direct from form_structure.json
- entry_bounding_box = [checkbox.x0, checkbox.top, checkbox.x1, checkbox.bottom]

Make fields.json using `pdf_width` and `pdf_height` to signal PDF coords:
```json
{
  "pages": [
    {"page_number": 1, "pdf_width": 612, "pdf_height": 792}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [43, 63, 87, 73],
      "entry_bounding_box": [92, 63, 260, 79],
      "entry_text": {"text": "Smith", "font_size": 10}
    },
    {
      "page_number": 1,
      "description": "US Citizen Yes checkbox",
      "field_label": "Yes",
      "label_bounding_box": [260, 200, 280, 210],
      "entry_bounding_box": [285, 197, 292, 205],
      "entry_text": {"text": "X"}
    }
  ]
}
```

**Important**: Use `pdf_width`/`pdf_height` and coords direct from form_structure.json.

### A.4: Validate Bounding Boxes

Before filling, check bounding boxes for errors:
`python scripts/check_bounding_boxes.py fields.json`

This checks intersecting boxes and entry boxes too small for font size. Fix all reported errors before filling.

---

## Approach B: Visual Estimation (Fallback)

Use when PDF is scanned/image-based and structure extraction found no useful text labels, like all text appears as "(cid:X)" patterns.

### B.1: Convert PDF to Images

`python scripts/convert_pdf_to_images.py <input.pdf> <images_dir/>`

### B.2: Initial Field Identification

Look at each page image and find form sections plus **rough field locations**:
- Form labels and rough positions
- Entry areas like lines, boxes, or blank spaces for text input
- Checkboxes and rough positions

For each field, note rough pixel coords. No need exact yet.

### B.3: Zoom Refinement (CRITICAL for accuracy)

For each field, crop around rough position to refine coords exact.

**Make zoomed crop with ImageMagick:**
```bash
magick <page_image> -crop <width>x<height>+<x>+<y> +repage <crop_output.png>
```

Where:
- `<x>, <y>` = top-left of crop region (rough estimate minus padding)
- `<width>, <height>` = crop size (field area plus ~50px padding each side)

**Example:** To refine "Name" field rough near (100, 150):
```bash
magick images_dir/page_1.png -crop 300x80+50+120 +repage crops/name_field.png
```

(If `magick` missing, try `convert` with same args).

**Inspect cropped image** to find exact coords:
1. Exact pixel where entry area starts, after label
2. Where entry area ends, before next field or edge
3. Top and bottom of entry line/box

**Convert crop coords back to full image coords:**
- full_x = crop_x + crop_offset_x
- full_y = crop_y + crop_offset_y

Example: If crop started at (50, 120) and entry box starts at (52, 18) inside crop:
- entry_x0 = 52 + 50 = 102
- entry_top = 18 + 120 = 138

**Repeat for each field**. Group nearby fields into one crop when possible.

### B.4: Create fields.json with Refined Coordinates

Make fields.json using `image_width` and `image_height` to signal image coords:
```json
{
  "pages": [
    {"page_number": 1, "image_width": 1700, "image_height": 2200}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [120, 175, 242, 198],
      "entry_bounding_box": [255, 175, 720, 218],
      "entry_text": {"text": "Smith", "font_size": 10}
    }
  ]
}
```

**Important**: Use `image_width`/`image_height` and refined pixel coords from zoom analysis.

### B.5: Validate Bounding Boxes

Before filling, check bounding boxes for errors:
`python scripts/check_bounding_boxes.py fields.json`

This checks intersecting boxes and entry boxes too small for font size. Fix all reported errors before filling.

---

## Hybrid Approach: Structure + Visual

Use when structure extraction works for most fields but misses some elements, like circular checkboxes or unusual form controls.

1. **Use Approach A** for fields found in form_structure.json
2. **Convert PDF to images** for visual analysis of missing fields
3. **Use zoom refinement** from Approach B for missing fields
4. **Combine coordinates**: For structure fields, use `pdf_width`/`pdf_height`. For visually estimated fields, convert image coords to PDF coords:
   - pdf_x = image_x * (pdf_width / image_width)
   - pdf_y = image_y * (pdf_height / image_height)
5. **Use one coordinate system** in fields.json. Convert all to PDF coords with `pdf_width`/`pdf_height`

---

## Step 2: Validate Before Filling

**Always validate bounding boxes before filling:**
`python scripts/check_bounding_boxes.py fields.json`

This checks for:
- Intersecting bounding boxes that would overlap text
- Entry boxes too small for chosen font size

Fix all reported errors in fields.json before continue.

## Step 3: Fill the Form

Fill script auto-detect coordinate system and handle conversion:
`python scripts/fill_pdf_form_with_annotations.py <input.pdf> fields.json <output.pdf>`

## Step 4: Verify Output

Convert filled PDF to images and verify text placement:
`python scripts/convert_pdf_to_images.py <output.pdf> <verify_images/>`

If text misplaced:
- **Approach A**: Check using PDF coords from form_structure.json with `pdf_width`/`pdf_height`
- **Approach B**: Check image dimensions match and coords are exact pixels
- **Hybrid**: Make sure coord conversions correct for visually estimated fields