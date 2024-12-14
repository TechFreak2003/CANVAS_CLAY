// Incremental Animation for Stats
const statNumbers = document.querySelectorAll('.stat-number');

statNumbers.forEach(stat => {
    const updateCount = () => {
        const target = +stat.getAttribute('data-target');
        const count = +stat.innerText;

        const increment = target / 200;

        if (count < target) {
            stat.innerText = Math.ceil(count + increment);
            setTimeout(updateCount, 10);
        } else {
            stat.innerText = target;
        }
    };
    updateCount();
});
