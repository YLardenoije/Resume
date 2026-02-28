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
        const sections = document.querySelectorAll('section[id], header[id]');
        const navButtons = document.querySelectorAll('.control');
        
        const observer = new IntersectionObserver((entries) => {
            // Find the section with the highest intersection ratio
            let mostVisible = null;
            let highestRatio = 0;
            
            entries.forEach(entry => {
                if (entry.isIntersecting && entry.intersectionRatio > highestRatio) {
                    highestRatio = entry.intersectionRatio;
                    mostVisible = entry.target;
                }
            });
            
            // If we found a visible section, update navigation
            if (mostVisible) {
                // Remove active class from all nav buttons
                navButtons.forEach(btn => btn.classList.remove('active-btn'));
                
                // Add active class to the corresponding nav button
                const activeButton = document.querySelector(`.control[data-id="${mostVisible.id}"]`);
                if (activeButton) {
                    activeButton.classList.add('active-btn');
                }
            }
        }, {
            threshold: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], // Multiple thresholds for better detection
            rootMargin: '0px' // No margin adjustments for simpler behavior
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
