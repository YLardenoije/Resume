#!/usr/bin/env python3
"""
Skills Management Utility

This script helps you manage your skills data in the JSON file.
Run this script to easily add, remove, or update skills without manually editing JSON.

Usage:
    python manage_skills.py list                    # List all skills
    python manage_skills.py add "Skill Name" 80     # Add skill with percentage
    python manage_skills.py remove "Skill Name"     # Remove a skill
    python manage_skills.py update "Skill Name" 85  # Update skill percentage
"""

import json
import sys
import os
from pathlib import Path

# Path to the skills JSON file
SKILLS_FILE = Path(__file__).parent / "main" / "static" / "data" / "skills.json"

# Available color classes for styling
COLOR_CLASSES = ["html", "css", "js", "react", "node"]

def load_skills():
    """Load skills from JSON file"""
    try:
        with open(SKILLS_FILE, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return {"skills": []}
    except json.JSONDecodeError as e:
        print(f"Error reading JSON file: {e}")
        return {"skills": []}

def save_skills(data):
    """Save skills to JSON file"""
    try:
        # Ensure directory exists
        SKILLS_FILE.parent.mkdir(parents=True, exist_ok=True)
        
        with open(SKILLS_FILE, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"✅ Skills saved to {SKILLS_FILE}")
        return True
    except Exception as e:
        print(f"❌ Error saving skills: {e}")
        return False

def list_skills():
    """List all current skills"""
    data = load_skills()
    skills = data.get("skills", [])
    
    if not skills:
        print("No skills found.")
        return
    
    print("\n🎯 Current Skills:")
    print("-" * 50)
    for i, skill in enumerate(skills, 1):
        category = skill.get("category", "Uncategorized")
        print(f"{i:2d}. {skill['name']:<20} {skill['percentage']:>3d}% [{skill['colorClass']:<6}] ({category})")
    print("-" * 50)
    print(f"Total: {len(skills)} skills")

def add_skill(name, percentage, color_class=None, category=None):
    """Add a new skill"""
    data = load_skills()
    skills = data.get("skills", [])
    
    # Check if skill already exists
    if any(skill['name'].lower() == name.lower() for skill in skills):
        print(f"❌ Skill '{name}' already exists. Use 'update' to modify it.")
        return
    
    # Auto-assign color class if not provided
    if not color_class:
        used_colors = [skill.get('colorClass') for skill in skills]
        available_colors = [c for c in COLOR_CLASSES if used_colors.count(c) < 2]
        color_class = available_colors[0] if available_colors else COLOR_CLASSES[0]
    
    # Auto-assign category if not provided
    if not category:
        category = "General"
    
    new_skill = {
        "name": name,
        "percentage": int(percentage),
        "colorClass": color_class,
        "category": category
    }
    
    skills.append(new_skill)
    data["skills"] = skills
    
    if save_skills(data):
        print(f"✅ Added skill: {name} ({percentage}%)")

def remove_skill(name):
    """Remove a skill"""
    data = load_skills()
    skills = data.get("skills", [])
    
    original_count = len(skills)
    skills = [skill for skill in skills if skill['name'].lower() != name.lower()]
    
    if len(skills) == original_count:
        print(f"❌ Skill '{name}' not found.")
        return
    
    data["skills"] = skills
    if save_skills(data):
        print(f"✅ Removed skill: {name}")

def update_skill(name, percentage):
    """Update a skill's percentage"""
    data = load_skills()
    skills = data.get("skills", [])
    
    for skill in skills:
        if skill['name'].lower() == name.lower():
            old_percentage = skill['percentage']
            skill['percentage'] = int(percentage)
            
            if save_skills(data):
                print(f"✅ Updated {name}: {old_percentage}% → {percentage}%")
            return
    
    print(f"❌ Skill '{name}' not found.")

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    
    command = sys.argv[1].lower()
    
    if command == "list":
        list_skills()
    
    elif command == "add":
        if len(sys.argv) < 4:
            print("Usage: python manage_skills.py add \"Skill Name\" percentage [category]")
            return
        name = sys.argv[2]
        percentage = sys.argv[3]
        category = sys.argv[4] if len(sys.argv) > 4 else None
        add_skill(name, percentage, category=category)
    
    elif command == "remove":
        if len(sys.argv) < 3:
            print("Usage: python manage_skills.py remove \"Skill Name\"")
            return
        name = sys.argv[2]
        remove_skill(name)
    
    elif command == "update":
        if len(sys.argv) < 4:
            print("Usage: python manage_skills.py update \"Skill Name\" percentage")
            return
        name = sys.argv[2]
        percentage = sys.argv[3]
        update_skill(name, percentage)
    
    else:
        print(f"Unknown command: {command}")
        print(__doc__)

if __name__ == "__main__":
    main()
