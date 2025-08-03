(function () {
    // Navigation and smooth scrolling functionality
    [...document.querySelectorAll(".control")].forEach(button => {
        button.addEventListener("click", function() {
            // Update active navigation button
            document.querySelector(".active-btn").classList.remove("active-btn");
            this.classList.add("active-btn");
            
            // Smooth scroll to the target section
            const targetSection = document.getElementById(button.dataset.id);
            if (targetSection) {
                targetSection.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        })
    });
    document.querySelector(".theme-btn").addEventListener("click", () => {
        document.body.classList.toggle("light-mode");
    })

    // Intersection Observer for automatic navigation highlighting during scroll
    function updateActiveNavOnScroll() {
        const sections = document.querySelectorAll('section[id]');
        const navButtons = document.querySelectorAll('.control');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // Remove active class from all nav buttons
                    navButtons.forEach(btn => btn.classList.remove('active-btn'));
                    
                    // Add active class to the corresponding nav button
                    const activeButton = document.querySelector(`.control[data-id="${entry.target.id}"]`);
                    if (activeButton) {
                        activeButton.classList.add('active-btn');
                    }
                }
            });
        }, {
            threshold: 0.3, // Trigger when 30% of the section is visible
            rootMargin: '-10% 0px -60% 0px' // Adjust trigger area
        });

        sections.forEach(section => observer.observe(section));
    }

    // Initialize scroll-based navigation highlighting
    document.addEventListener('DOMContentLoaded', updateActiveNavOnScroll);

    // Skills progress bars generation
    function createProgressBar(skillName, percentage, colorClass) {
        return `
            <div class="progress-bar">
                <p class="prog-title">${skillName}</p>
                <div class="progress-con">
                    <p class="prog-text">${percentage}%</p>
                    <div class="progress">
                        <span class="${colorClass}" style="width: ${percentage}%;"></span>
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
                { name: 'C++', percentage: 85, colorClass: 'color-primary', category: 'Programming Languages' },
                { name: 'C', percentage: 80, colorClass: 'color-red', category: 'Programming Languages' },
                { name: 'Agile', percentage: 75, colorClass: 'color-orange', category: 'Methodologies' },
                { name: 'Python', percentage: 75, colorClass: 'color-purple', category: 'Programming Languages' },
                { name: 'Git', percentage: 80, colorClass: 'color-teal', category: 'Tools' }
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
