(function () {
    // Navigation and theme functionality
    [...document.querySelectorAll(".control")].forEach(button => {
        button.addEventListener("click", function() {
            document.querySelector(".active-btn").classList.remove("active-btn");
            this.classList.add("active-btn");
            document.querySelector(".active").classList.remove("active");
            document.getElementById(button.dataset.id).classList.add("active");
        })
    });
    document.querySelector(".theme-btn").addEventListener("click", () => {
        document.body.classList.toggle("light-mode");
    })

    // Skills progress bars generation
    function createProgressBar(skillName, percentage, colorClass) {
        return `
            <div class="progress-bar">
                <p class="prog-title">${skillName}</p>
                <div class="progress-con">
                    <p class="prog-text">${percentage}%</p>
                    <div class="progress">
                        <span class="${colorClass}"></span>
                    </div>
                </div>
            </div>
        `;
    }

    async function loadSkillsFromJSON() {
        try {
            // Fetch skills data from JSON file
            const response = await fetch('/static/data/skills.json');
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            return data.skills;
        } catch (error) {
            console.error('Error loading skills data:', error);
            
            // Fallback skills data if JSON loading fails
            return [
                { name: 'C++', percentage: 85, colorClass: 'html', category: 'Programming Languages' },
                { name: 'C', percentage: 80, colorClass: 'css', category: 'Programming Languages' },
                { name: 'Agile', percentage: 75, colorClass: 'js', category: 'Methodologies' },
                { name: 'Python', percentage: 75, colorClass: 'react', category: 'Programming Languages' },
                { name: 'Git', percentage: 80, colorClass: 'node', category: 'Tools' }
            ];
        }
    }

    async function renderSkills() {
        // Load skills from JSON file
        const skills = await loadSkillsFromJSON();

        // Find the progress-bars container
        const progressBarsContainer = document.querySelector('.progress-bars');
        
        if (progressBarsContainer) {
            // Show loading state
            progressBarsContainer.innerHTML = '<p>Loading skills...</p>';
            
            // Generate HTML for all skills
            const skillsHTML = skills.map(skill => 
                createProgressBar(skill.name, skill.percentage, skill.colorClass)
            ).join('');
            
            // Insert the generated HTML
            progressBarsContainer.innerHTML = skillsHTML;
            
            console.log(`Loaded ${skills.length} skills from JSON`);
        }
    }

    // Initialize skills when DOM is loaded
    document.addEventListener('DOMContentLoaded', renderSkills);
})();
