# Skills Management System

## Overview

The skills section has been refactored to use JavaScript with JSON data loading for dynamic content generation, making it extremely easy to maintain and update your skills list without touching any code.

## How It Works

### 1. Template Structure
The `main/templates/main/partials/skills.html` file contains only the container structure:
- A title "My Skills"  
- An empty `<div class="progress-bars">` container
- The JavaScript populates this container dynamically

### 2. JSON Data Source
Skills data is stored in `main/static/data/skills.json`:
- Centralized data configuration
- Easy to edit without code knowledge
- Supports additional metadata (categories, descriptions, etc.)

### 3. JavaScript Generation
The `main/static/app.js` file contains:
- `createProgressBar()` function: Generates HTML for individual skill bars
- `loadSkillsFromJSON()` function: Fetches skills data from JSON file
- `renderSkills()` function: Renders all skills from the loaded data
- Error handling with fallback data

## Adding/Modifying Skills

To update your skills, edit the `main/static/data/skills.json` file:

```json
{
  "skills": [
    {
      "name": "C++",
      "percentage": 85,
      "colorClass": "color-primary",
      "category": "Programming Languages"
    },
    {
      "name": "JavaScript",
      "percentage": 70,
      "colorClass": "color-orange",
      "category": "Programming Languages"
    },
    {
      "name": "Docker",
      "percentage": 65,
      "colorClass": "color-teal",
      "category": "Tools"
    }
  ]
}
```

### Skill Object Properties:
- **name**: Display name of the skill (string) - *Required*
- **percentage**: Proficiency level 0-100 (number) - *Required*
- **colorClass**: CSS class for progress bar color (string) - *Required*
- **category**: Skill category for organization (string) - *Optional*

### Available Color Classes:
- `color-primary` - Uses the site's primary color (green)
- `color-red` - Red progress bar
- `color-orange` - Orange progress bar  
- `color-purple` - Purple progress bar
- `color-teal` - Teal progress bar

*Note: The width of each progress bar is automatically set to match the percentage value from the JSON data.*

## Benefits of This Approach

1. **No Code Required**: Update skills by editing JSON - no programming needed
2. **Easy Maintenance**: All skills data in one structured file
3. **No HTML Repetition**: Template code is clean and minimal
4. **Dynamic Loading**: Skills load asynchronously from JSON file
5. **Consistent Structure**: All progress bars have identical HTML structure
6. **Error Handling**: Fallback data if JSON loading fails
7. **Extensible**: Easy to add metadata like categories, descriptions, etc.
8. **Version Control Friendly**: JSON changes are easy to track in git

## Example: Adding a New Skill

To add "Docker" with 60% proficiency, add this to your `skills.json`:

```json
{
  "name": "Docker",
  "percentage": 60,
  "colorClass": "color-primary",
  "category": "DevOps Tools"
}
```

## File Structure

```
Resume/
├── manage_skills.py           # Python script for easy skills management
└── main/static/
    ├── app.js                 # JavaScript logic for loading and rendering
    └── data/
        └── skills.json        # Skills data (edit this file to update skills)
```

## Easy Management with Python Script

For even easier management, use the included Python script:

```bash
# List all current skills
python3 manage_skills.py list

# Add a new skill
python3 manage_skills.py add "Docker" 60 "DevOps Tools"

# Update an existing skill
python3 manage_skills.py update "Python" 80

# Remove a skill
python3 manage_skills.py remove "Agile"
```

## Manual JSON Editing

You can also directly edit `main/static/data/skills.json`:

## Troubleshooting

- **Skills not showing**: Check browser console for JavaScript errors or network issues
- **JSON not loading**: Verify the file path `/static/data/skills.json` is accessible
- **Wrong colors**: Verify `colorClass` matches available CSS classes
- **Styling issues**: Ensure CSS classes (`html`, `css`, `js`, `react`, `node`) are defined
- **Invalid JSON**: Use a JSON validator to check file syntax

The system automatically loads skills data from JSON and generates all the HTML structure, making your skills section incredibly maintainable!
