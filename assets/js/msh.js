document.addEventListener('DOMContentLoaded', () => {
  const notify = message => {
    let toast = document.querySelector('.toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.className = 'toast';
      toast.setAttribute('role', 'status');
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 2800);
  };
  const menu = document.querySelector('.menu');
  const links = document.querySelector('.navlinks');
  menu?.addEventListener('click', () => {
    const open = links.classList.toggle('open');
    menu.setAttribute('aria-expanded', String(open));
  });
  document.querySelectorAll('[data-filter]').forEach(button => button.addEventListener('click', () => {
    document.querySelectorAll('[data-filter]').forEach(item => item.classList.remove('active'));
    button.classList.add('active');
    const value = button.dataset.filter;
    const cards = button.closest('section') ? button.closest('section').querySelectorAll('[data-cat]') : document.querySelectorAll('[data-cat]');
    cards.forEach(card => card.classList.toggle('hidden', value !== 'todos' && card.dataset.cat !== value));
  }));
  document.querySelectorAll('form[data-demo]').forEach(form => form.addEventListener('submit', event => {
    event.preventDefault();
    notify(form.dataset.message || 'Listo. Recibimos tu mensaje.');
  }));
  document.querySelectorAll('[data-copy]').forEach(button => button.addEventListener('click', () => {
    notify('Descarga de demostración preparada.');
  }));
});
