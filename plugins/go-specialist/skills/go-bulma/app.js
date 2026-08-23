// internal/ui/static/app.js
// Vanilla JS helpers for Bulma's interactive components.
// Bulma ships zero JS by design; this file wires the standard idioms
// documented at https://bulma.io/documentation/.

(() => {
  // Navbar burger: toggle .is-active on burger + matching menu.
  document.querySelectorAll('.navbar-burger').forEach((burger) => {
    burger.addEventListener('click', () => {
      const target = document.getElementById(burger.dataset.target);
      burger.classList.toggle('is-active');
      if (target) target.classList.toggle('is-active');
    });
  });

  // Modal: any element with data-target="modal-id" opens that modal.
  // .modal-background, .modal-close, .delete (inside .modal), and Escape close it.
  const openModal = (el) => el.classList.add('is-active');
  const closeModal = (el) => el.classList.remove('is-active');
  const closeAllModals = () =>
    document.querySelectorAll('.modal.is-active').forEach(closeModal);

  document.querySelectorAll('[data-target]').forEach((trigger) => {
    const target = document.getElementById(trigger.dataset.target);
    if (target && target.classList.contains('modal')) {
      trigger.addEventListener('click', () => openModal(target));
    }
  });

  document
    .querySelectorAll('.modal-background, .modal-close, .modal-card-head .delete, .modal .delete')
    .forEach((el) => {
      const modal = el.closest('.modal');
      if (modal) el.addEventListener('click', () => closeModal(modal));
    });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeAllModals();
  });

  // Dropdown: click .dropdown-trigger to toggle, click outside to close.
  document.querySelectorAll('.dropdown:not(.is-hoverable)').forEach((dropdown) => {
    const trigger = dropdown.querySelector('.dropdown-trigger');
    if (!trigger) return;
    trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      dropdown.classList.toggle('is-active');
    });
  });
  document.addEventListener('click', () => {
    document
      .querySelectorAll('.dropdown.is-active:not(.is-hoverable)')
      .forEach((d) => d.classList.remove('is-active'));
  });

  // Tabs: <div class="tabs"><ul><li data-tab="panel-id">...</li></ul></div>
  // Panels are any elements with id matching data-tab; only the active one shows.
  document.querySelectorAll('.tabs').forEach((tabs) => {
    const items = tabs.querySelectorAll('li[data-tab]');
    items.forEach((item) => {
      item.addEventListener('click', () => {
        items.forEach((i) => i.classList.remove('is-active'));
        item.classList.add('is-active');
        items.forEach((i) => {
          const panel = document.getElementById(i.dataset.tab);
          if (panel) panel.hidden = i !== item;
        });
      });
    });
  });
})();
