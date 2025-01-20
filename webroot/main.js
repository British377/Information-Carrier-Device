function initTabs() {
    const tabs = document.querySelectorAll('.tab-button');
    const contents = document.querySelectorAll('.tab-content');
    
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            // Remove active class from all tabs and contents
            tabs.forEach(t => t.classList.remove('active'));
            contents.forEach(c => c.classList.remove('active'));
            
            // Add active class to clicked tab and corresponding content
            tab.classList.add('active');
            const contentId = tab.getAttribute('data-tab');
            document.getElementById(contentId).classList.add('active');
        });
    });
}

document.addEventListener('DOMContentLoaded', () => {
    // Theme switcher
    const themeToggle = document.getElementById('theme-toggle');
    
    themeToggle.addEventListener('change', () => {
        document.body.dataset.theme = themeToggle.checked ? 'dark' : 'light';
        localStorage.setItem('theme', themeToggle.checked ? 'dark' : 'light');
    });

    // Load saved theme
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
        document.body.dataset.theme = savedTheme;
        themeToggle.checked = savedTheme === 'dark';
    }

    function updateBatteryIndicator(percentage) {
        const batteryLevel = document.getElementById('battery-level-visual');
        const level = parseInt(percentage);
        
        batteryLevel.style.width = `${level}%`;
        
        if (level <= 20) {
            batteryLevel.style.background = '#f56565';
        } else if (level <= 50) {
            batteryLevel.style.background = '#ecc94b';
        } else {
            batteryLevel.style.background = '#48bb78';
        }
    }

    function updateDateTime() {
        const now = new Date();
        document.getElementById('last-update').textContent = now.toLocaleString();
    }

    function updateStatus() {
        fetch('index.html')
            .then(response => response.text())
            .then(html => {
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                
                // Обновление всех значений в карточке Battery Information
                document.querySelectorAll('.card:first-child .info-item .value').forEach(element => {
                    if (element.id) { // Проверяем наличие ID
                        const newElement = doc.querySelector(`#${element.id}`);
                        if (newElement && element.textContent !== newElement.textContent) {
                            element.textContent = newElement.textContent;
                            element.classList.add('value-changed');
                            setTimeout(() => element.classList.remove('value-changed'), 300);
                        }
                    }
                });
    
                // Обновление всех значений во всех табах System Information
                ['device', 'kernel', 'performance'].forEach(tabId => {
                    document.querySelectorAll(`#${tabId} .info-item .value`).forEach(element => {
                        if (element.id) {
                            const newElement = doc.querySelector(`#${element.id}`);
                            if (newElement && element.textContent !== newElement.textContent) {
                                element.textContent = newElement.textContent;
                                element.classList.add('value-changed');
                                setTimeout(() => element.classList.remove('value-changed'), 300);
                            }
                        }
                    });
                });
    
                // Обновление CPU details
                document.querySelectorAll('.cpu-details .info-item .value').forEach(element => {
                    if (element.id) {
                        const newElement = doc.querySelector(`#${element.id}`);
                        if (newElement && element.textContent !== newElement.textContent) {
                            element.textContent = newElement.textContent;
                            element.classList.add('value-changed');
                            setTimeout(() => element.classList.remove('value-changed'), 300);
                        }
                    }
                });
    
                updateDateTime();
            });
    }

    // Update status every 1 seconds
    setInterval(updateStatus, 1000);
    updateStatus();
    initTabs();
});

// Add smooth transitions for status changes
const observeValues = () => {
    const values = document.querySelectorAll('.value');
    values.forEach(value => {
        const observer = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
                if (mutation.type === 'characterData' || mutation.type === 'childList') {
                    value.classList.add('value-changed');
                    setTimeout(() => value.classList.remove('value-changed'), 300);
                }
            });
        });

        observer.observe(value, {
            characterData: true,
            childList: true,
            subtree: true
        });
    });
};

observeValues();