// ========================================
// Bookmarks Modal Logic
// ========================================

// Active tab: 'upfront' | 'shelf'
let _bmActiveTab = 'upfront';

// The visual editor intentionally keeps its own transient IDs. Persisted
// settings remain the existing flat { href, title, category? } array.
let _bmGroups = [];
let _bmIdCounter = 0;
let _bmDragState = null;
let _bmFocusRequest = null;

function _bmNewId(prefix) {
  _bmIdCounter += 1;
  return prefix + '-' + _bmIdCounter;
}

function _bmCleanText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function _bmBookmarkFromValue(bookmark) {
  return {
    id: _bmNewId('bookmark'),
    title: _bmCleanText(bookmark?.title),
    href: _bmCleanText(bookmark?.href),
  };
}

function _bmGroupsFromBookmarks(bookmarks) {
  const groups = [];
  const byCategory = new Map();

  (Array.isArray(bookmarks) ? bookmarks : []).forEach(bookmark => {
    if (!bookmark || typeof bookmark !== 'object') return;

    // This matches the startpage renderer's existing fallback for bookmarks
    // without a category.
    const category = _bmCleanText(bookmark.category) || 'other';
    let group = byCategory.get(category);
    if (!group) {
      group = {
        id: _bmNewId('group'),
        name: category,
        bookmarks: [],
      };
      byCategory.set(category, group);
      groups.push(group);
    }

    const entry = _bmBookmarkFromValue(bookmark);
    if (entry.title || entry.href) group.bookmarks.push(entry);
  });

  return groups;
}

function _bmGetEditor() {
  return document.getElementById('bookmarks-group-editor');
}

function _bmGetGroup(groupId) {
  return _bmGroups.find(group => group.id === groupId) || null;
}

function _bmButton(label, className, title, onClick) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = className;
  button.textContent = label;
  button.title = title;
  button.setAttribute('aria-label', title);
  button.addEventListener('click', onClick);
  return button;
}

function _bmRequestFocus(kind, id) {
  _bmFocusRequest = { kind, id };
}

function _bmApplyFocusRequest() {
  if (!_bmFocusRequest) return;
  const request = _bmFocusRequest;
  _bmFocusRequest = null;

  window.requestAnimationFrame(() => {
    const selector = request.kind === 'group'
      ? '#bm-group-name-' + request.id
      : '#bm-bookmark-title-' + request.id;
    const input = document.querySelector(selector);
    if (input) input.focus();
  });
}

function _bmClearDropIndicators() {
  document.querySelectorAll(
    '.bookmark-group-card.is-dragging, .bookmark-group-card.is-drop-target, .bookmark-group-list.is-drop-target, .bookmark-row.is-dragging, .bookmark-row.is-drop-target'
  ).forEach(element => {
    element.classList.remove('is-dragging', 'is-drop-target');
  });
}

function _bmResetDragState() {
  _bmClearDropIndicators();
  _bmDragState = null;
}

function _bmMoveArrayItem(items, fromIndex, toIndex) {
  if (fromIndex < 0 || fromIndex >= items.length || toIndex < 0 || toIndex >= items.length || fromIndex === toIndex) return;
  const [item] = items.splice(fromIndex, 1);
  items.splice(toIndex, 0, item);
}

function _bmMoveGroup(groupId, delta) {
  const index = _bmGroups.findIndex(group => group.id === groupId);
  const target = index + delta;
  _bmMoveArrayItem(_bmGroups, index, target);
  renderGroupedEditor();
}

function _bmMoveBookmarkWithinGroup(groupId, bookmarkId, delta) {
  const group = _bmGetGroup(groupId);
  if (!group) return;
  const index = group.bookmarks.findIndex(bookmark => bookmark.id === bookmarkId);
  _bmMoveArrayItem(group.bookmarks, index, index + delta);
  renderGroupedEditor();
}

function _bmMoveBookmarkTo(groupId, bookmarkId, targetGroupId, targetBookmarkId = null, placeAfter = false) {
  const sourceGroup = _bmGetGroup(groupId);
  const targetGroup = _bmGetGroup(targetGroupId);
  if (!sourceGroup || !targetGroup) return;

  const sourceIndex = sourceGroup.bookmarks.findIndex(bookmark => bookmark.id === bookmarkId);
  if (sourceIndex === -1) return;

  const [bookmark] = sourceGroup.bookmarks.splice(sourceIndex, 1);
  let targetIndex = targetBookmarkId
    ? targetGroup.bookmarks.findIndex(item => item.id === targetBookmarkId)
    : targetGroup.bookmarks.length;

  if (targetIndex === -1) targetIndex = targetGroup.bookmarks.length;
  if (placeAfter && targetBookmarkId) targetIndex += 1;

  targetGroup.bookmarks.splice(targetIndex, 0, bookmark);
  renderGroupedEditor();
}

function _bmAddGroup() {
  const names = new Set(_bmGroups.map(group => _bmCleanText(group.name)));
  let suffix = 1;
  let name = 'New group';
  while (names.has(name)) {
    suffix += 1;
    name = 'New group ' + suffix;
  }

  const group = {
    id: _bmNewId('group'),
    name,
    bookmarks: [],
  };
  _bmGroups.push(group);
  _bmRequestFocus('group', group.id);
  renderGroupedEditor();
}

function _bmDeleteEmptyGroup(groupId) {
  const group = _bmGetGroup(groupId);
  if (!group || group.bookmarks.length) return;
  _bmGroups = _bmGroups.filter(item => item.id !== groupId);
  renderGroupedEditor();
}

function _bmAddBookmark(groupId) {
  const group = _bmGetGroup(groupId);
  if (!group) return;
  const bookmark = {
    id: _bmNewId('bookmark'),
    title: '',
    href: '',
  };
  group.bookmarks.push(bookmark);
  _bmRequestFocus('bookmark', bookmark.id);
  renderGroupedEditor();
}

function _bmRemoveBookmark(groupId, bookmarkId) {
  const group = _bmGetGroup(groupId);
  if (!group) return;
  group.bookmarks = group.bookmarks.filter(bookmark => bookmark.id !== bookmarkId);
  renderGroupedEditor();
}

function _bmGroupDragStart(event, groupId, card) {
  _bmDragState = { type: 'group', groupId };
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', groupId);
  card.classList.add('is-dragging');
}

function _bmBookmarkDragStart(event, groupId, bookmarkId, row) {
  _bmDragState = { type: 'bookmark', groupId, bookmarkId };
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', bookmarkId);
  row.classList.add('is-dragging');
}

function _bmAddGroupCard(editor, group, index) {
  const card = document.createElement('section');
  card.className = 'bookmark-group-card';
  card.dataset.groupId = group.id;
  card.setAttribute('aria-label', 'Bookmark group ' + (group.name || 'unnamed'));

  card.addEventListener('dragover', event => {
    if (_bmDragState?.type !== 'group' || _bmDragState.groupId === group.id) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    _bmClearDropIndicators();
    card.classList.add('is-drop-target');
  });
  card.addEventListener('dragleave', event => {
    if (!card.contains(event.relatedTarget)) card.classList.remove('is-drop-target');
  });
  card.addEventListener('drop', event => {
    if (_bmDragState?.type !== 'group' || _bmDragState.groupId === group.id) return;
    event.preventDefault();
    event.stopPropagation();

    const sourceIndex = _bmGroups.findIndex(item => item.id === _bmDragState.groupId);
    const targetIndex = _bmGroups.findIndex(item => item.id === group.id);
    const rect = card.getBoundingClientRect();
    const targetAfter = event.clientY > rect.top + rect.height / 2;
    let destination = targetIndex + (targetAfter ? 1 : 0);
    if (sourceIndex < destination) destination -= 1;

    if (sourceIndex !== -1) {
      const [dragged] = _bmGroups.splice(sourceIndex, 1);
      _bmGroups.splice(destination, 0, dragged);
    }
    _bmResetDragState();
    renderGroupedEditor();
  });

  const header = document.createElement('div');
  header.className = 'bookmark-group-header';

  const dragHandle = _bmButton('⠿', 'bookmark-group-drag-handle', 'Drag group ' + group.name, () => {});
  dragHandle.draggable = true;
  dragHandle.addEventListener('dragstart', event => _bmGroupDragStart(event, group.id, card));
  dragHandle.addEventListener('dragend', _bmResetDragState);
  header.appendChild(dragHandle);

  const nameInput = document.createElement('input');
  nameInput.id = 'bm-group-name-' + group.id;
  nameInput.type = 'text';
  nameInput.className = 'bookmark-group-name-input';
  nameInput.value = group.name;
  nameInput.placeholder = 'Group name';
  nameInput.spellcheck = false;
  nameInput.autocomplete = 'off';
  nameInput.setAttribute('aria-label', 'Group name');
  nameInput.addEventListener('input', () => {
    group.name = nameInput.value;
    card.setAttribute('aria-label', 'Bookmark group ' + (_bmCleanText(group.name) || 'unnamed'));
    dragHandle.title = 'Drag group ' + (_bmCleanText(group.name) || 'unnamed');
    dragHandle.setAttribute('aria-label', dragHandle.title);
  });
  header.appendChild(nameInput);

  const count = document.createElement('span');
  count.className = 'bookmark-group-count';
  count.textContent = group.bookmarks.length + (group.bookmarks.length === 1 ? ' bookmark' : ' bookmarks');
  header.appendChild(count);

  const actions = document.createElement('div');
  actions.className = 'bookmark-group-actions';

  const moveUp = _bmButton('↑', 'bookmark-move-btn', 'Move group up', () => _bmMoveGroup(group.id, -1));
  moveUp.disabled = index === 0;
  actions.appendChild(moveUp);

  const moveDown = _bmButton('↓', 'bookmark-move-btn', 'Move group down', () => _bmMoveGroup(group.id, 1));
  moveDown.disabled = index === _bmGroups.length - 1;
  actions.appendChild(moveDown);

  const deleteGroup = _bmButton('×', 'bookmark-delete-group-btn', 'Delete empty group', () => _bmDeleteEmptyGroup(group.id));
  deleteGroup.disabled = group.bookmarks.length > 0;
  if (deleteGroup.disabled) {
    const message = 'Move or remove every bookmark before deleting this group';
    deleteGroup.title = message;
    deleteGroup.setAttribute('aria-label', message);
  }
  actions.appendChild(deleteGroup);

  header.appendChild(actions);
  card.appendChild(header);

  const list = document.createElement('div');
  list.className = 'bookmark-group-list';
  list.dataset.groupId = group.id;
  list.setAttribute('aria-label', 'Bookmarks in ' + (group.name || 'this group'));

  list.addEventListener('dragover', event => {
    if (_bmDragState?.type !== 'bookmark') return;
    event.preventDefault();
    event.stopPropagation();
    event.dataTransfer.dropEffect = 'move';
    _bmClearDropIndicators();
    list.classList.add('is-drop-target');
  });
  list.addEventListener('dragleave', event => {
    if (!list.contains(event.relatedTarget)) list.classList.remove('is-drop-target');
  });
  list.addEventListener('drop', event => {
    if (_bmDragState?.type !== 'bookmark') return;
    event.preventDefault();
    event.stopPropagation();
    _bmMoveBookmarkTo(_bmDragState.groupId, _bmDragState.bookmarkId, group.id);
    _bmResetDragState();
  });

  group.bookmarks.forEach((bookmark, bookmarkIndex) => {
    _bmAddBookmarkRow(list, group, bookmark, bookmarkIndex);
  });

  if (!group.bookmarks.length) {
    const emptyHint = document.createElement('div');
    emptyHint.className = 'bookmark-group-empty-hint';
    emptyHint.textContent = 'Drop a bookmark here or add one below.';
    list.appendChild(emptyHint);
  }

  card.appendChild(list);

  const addBookmark = _bmButton('+ Add bookmark', 'bookmark-add-row-btn', 'Add bookmark to ' + group.name, () => _bmAddBookmark(group.id));
  addBookmark.dataset.bmAction = 'add-bookmark';
  card.appendChild(addBookmark);

  editor.appendChild(card);
}

function _bmAddBookmarkRow(list, group, bookmark, index) {
  const row = document.createElement('div');
  row.className = 'bookmark-row';
  row.dataset.bookmarkId = bookmark.id;

  row.addEventListener('dragover', event => {
    if (_bmDragState?.type !== 'bookmark' || _bmDragState.bookmarkId === bookmark.id) return;
    event.preventDefault();
    event.stopPropagation();
    event.dataTransfer.dropEffect = 'move';
    _bmClearDropIndicators();
    row.classList.add('is-drop-target');
  });
  row.addEventListener('dragleave', event => {
    if (!row.contains(event.relatedTarget)) row.classList.remove('is-drop-target');
  });
  row.addEventListener('drop', event => {
    if (_bmDragState?.type !== 'bookmark' || _bmDragState.bookmarkId === bookmark.id) return;
    event.preventDefault();
    event.stopPropagation();
    const rect = row.getBoundingClientRect();
    const placeAfter = event.clientY > rect.top + rect.height / 2;
    _bmMoveBookmarkTo(_bmDragState.groupId, _bmDragState.bookmarkId, group.id, bookmark.id, placeAfter);
    _bmResetDragState();
  });

  const dragHandle = _bmButton('⠿', 'bookmark-row-drag-handle', 'Drag bookmark ' + (bookmark.title || bookmark.href || 'new bookmark'), () => {});
  dragHandle.draggable = true;
  dragHandle.addEventListener('dragstart', event => _bmBookmarkDragStart(event, group.id, bookmark.id, row));
  dragHandle.addEventListener('dragend', _bmResetDragState);
  row.appendChild(dragHandle);

  const titleInput = document.createElement('input');
  titleInput.id = 'bm-bookmark-title-' + bookmark.id;
  titleInput.type = 'text';
  titleInput.className = 'bookmark-row-title-input';
  titleInput.placeholder = 'Title';
  titleInput.value = bookmark.title;
  titleInput.spellcheck = false;
  titleInput.autocomplete = 'off';
  titleInput.setAttribute('aria-label', 'Bookmark title');
  titleInput.addEventListener('input', () => {
    bookmark.title = titleInput.value;
    dragHandle.title = 'Drag bookmark ' + (_bmCleanText(bookmark.title) || _bmCleanText(bookmark.href) || 'new bookmark');
    dragHandle.setAttribute('aria-label', dragHandle.title);
  });
  row.appendChild(titleInput);

  const urlInput = document.createElement('input');
  urlInput.type = 'text';
  urlInput.className = 'bookmark-row-url-input';
  urlInput.placeholder = 'https://...';
  urlInput.value = bookmark.href;
  urlInput.spellcheck = false;
  urlInput.autocomplete = 'off';
  urlInput.setAttribute('aria-label', 'Bookmark URL');
  urlInput.addEventListener('input', () => {
    bookmark.href = urlInput.value;
    dragHandle.title = 'Drag bookmark ' + (_bmCleanText(bookmark.title) || _bmCleanText(bookmark.href) || 'new bookmark');
    dragHandle.setAttribute('aria-label', dragHandle.title);
  });
  row.appendChild(urlInput);

  const actions = document.createElement('div');
  actions.className = 'bookmark-row-actions';

  const moveUp = _bmButton('↑', 'bookmark-move-btn', 'Move bookmark up', () => _bmMoveBookmarkWithinGroup(group.id, bookmark.id, -1));
  moveUp.disabled = index === 0;
  actions.appendChild(moveUp);

  const moveDown = _bmButton('↓', 'bookmark-move-btn', 'Move bookmark down', () => _bmMoveBookmarkWithinGroup(group.id, bookmark.id, 1));
  moveDown.disabled = index === group.bookmarks.length - 1;
  actions.appendChild(moveDown);

  actions.appendChild(_bmButton('×', 'bookmark-remove-btn', 'Remove bookmark', () => _bmRemoveBookmark(group.id, bookmark.id)));
  row.appendChild(actions);

  list.appendChild(row);
}

function renderGroupedEditor(bookmarks = null) {
  const editor = _bmGetEditor();
  if (!editor) return;

  if (bookmarks !== null) _bmGroups = _bmGroupsFromBookmarks(bookmarks);
  const shelfEditor = document.getElementById('shelf-list-editor');
  editor.classList.remove('hidden');
  if (shelfEditor) shelfEditor.classList.add('hidden');
  editor.innerHTML = '';

  const toolbar = document.createElement('div');
  toolbar.className = 'bookmark-groups-toolbar';

  const hint = document.createElement('span');
  hint.className = 'bookmark-groups-hint';
  hint.textContent = 'Drag groups or bookmarks to reorder. Drag a bookmark to another group to move it.';
  toolbar.appendChild(hint);

  const addGroup = _bmButton('+ Add group', 'bookmark-add-group-btn', 'Add a bookmark group', _bmAddGroup);
  addGroup.dataset.bmAction = 'add-group';
  toolbar.appendChild(addGroup);
  editor.appendChild(toolbar);

  _bmGroups.forEach((group, index) => _bmAddGroupCard(editor, group, index));

  if (!_bmGroups.length) {
    const empty = document.createElement('div');
    empty.className = 'bookmark-editor-empty';
    empty.textContent = 'Add a group, then add at least one bookmark before saving.';
    editor.appendChild(empty);
  }

  _bmApplyFocusRequest();
}

function _bmCollectGroupedBookmarks() {
  if (!_bmGroups.length) throw new Error('Add a group and at least one bookmark before saving.');

  const categories = new Set();
  const bookmarks = [];

  _bmGroups.forEach(group => {
    const category = _bmCleanText(group.name);
    if (!category) throw new Error('Every group needs a name.');
    if (categories.has(category)) throw new Error('Group names must be unique.');
    categories.add(category);

    let validBookmarks = 0;
    group.bookmarks.forEach(bookmark => {
      const title = _bmCleanText(bookmark.title);
      const href = _bmCleanText(bookmark.href);
      if (!title && !href) return;
      validBookmarks += 1;
      bookmarks.push({
        title: title || href,
        href: href || '#',
        category,
      });
    });

    if (!validBookmarks) {
      throw new Error('Add a bookmark to "' + category + '" or delete the empty group.');
    }
  });

  if (!bookmarks.length) throw new Error('Add at least one bookmark before saving.');
  return bookmarks;
}

function openBookmarksModal() {
  _bmGroups = _bmGroupsFromBookmarks(getStoredBookmarks());
  _bmActiveTab = 'upfront';
  _bmSwitchTab('upfront');

  // Wire tab buttons — CSP forbids inline onclick, so we do it here.
  document.querySelectorAll('.bm-tab-btn').forEach(btn => {
    const fresh = btn.cloneNode(true);
    btn.parentNode.replaceChild(fresh, btn);
  });
  document.querySelectorAll('.bm-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => _bmSwitchTab(btn.dataset.tab));
  });

  const saveBtn = document.getElementById('btn-save-bookmarks');
  if (saveBtn) {
    saveBtn.disabled = false;
    saveBtn.title = '';
    saveBtn.textContent = 'Save';
  }

  document.getElementById('bookmarks-modal').classList.add('active');

  const handleEsc = event => {
    if (event.key === 'Escape') {
      closeBookmarksModal();
      document.removeEventListener('keydown', handleEsc);
    }
  };
  const cleanupEsc = () => {
    if (!document.getElementById('bookmarks-modal').classList.contains('active')) {
      document.removeEventListener('keydown', handleEsc);
      document.removeEventListener('click', cleanupEsc);
    }
  };
  document.addEventListener('keydown', handleEsc);
  document.addEventListener('click', cleanupEsc);
}

function closeBookmarksModal() {
  _bmResetDragState();
  document.getElementById('bookmarks-modal').classList.remove('active');
}

// ---- Tab switching ----
function _bmSwitchTab(tab) {
  _bmActiveTab = tab;

  document.querySelectorAll('.bm-tab-btn').forEach(btn => {
    btn.classList.toggle('bm-tab-active', btn.dataset.tab === tab);
  });

  const editor = _bmGetEditor();
  const textarea = document.getElementById('config-textarea');
  const toggleBtn = document.getElementById('toggle-editor-btn');

  if (tab === 'shelf') {
    if (editor) editor.classList.add('hidden');
    textarea.classList.add('hidden');
    if (toggleBtn) toggleBtn.textContent = 'View as JSON';
    _renderShelfEditor(getStoredShelfBookmarks());
    return;
  }

  textarea.classList.add('hidden');
  if (toggleBtn) toggleBtn.textContent = 'View as JSON';
  renderGroupedEditor();
}

// ========================================
// Shelf list editor (infinite, scrollable)
// ========================================
function _renderShelfEditor(bookmarks) {
  const editor = _bmGetEditor();
  const textarea = document.getElementById('config-textarea');
  if (editor) editor.classList.add('hidden');
  textarea.classList.add('hidden');

  let shelfEditor = document.getElementById('shelf-list-editor');
  if (!shelfEditor) {
    shelfEditor = document.createElement('div');
    shelfEditor.id = 'shelf-list-editor';
    editor.parentNode.insertBefore(shelfEditor, editor);
  }
  shelfEditor.classList.remove('hidden');
  shelfEditor.innerHTML = '';

  const addBtn = document.createElement('button');
  addBtn.className = 'shelf-add-btn';
  addBtn.textContent = '+ Add bookmark';
  addBtn.disabled = false;
  addBtn.title = '';
  addBtn.addEventListener('click', () => _shelfAddRow());
  shelfEditor.appendChild(addBtn);

  const list = document.createElement('div');
  list.id = 'shelf-list';
  list.className = 'shelf-list';
  shelfEditor.appendChild(list);

  bookmarks.forEach(bookmark => _shelfAddRow(bookmark, list));
}

function _shelfAddRow(bookmark = null, listEl = null) {
  const list = listEl || document.getElementById('shelf-list');
  if (!list) return;

  const row = document.createElement('div');
  row.className = 'shelf-row';

  const titleInput = document.createElement('input');
  titleInput.type = 'text';
  titleInput.className = 'shelf-title-input';
  titleInput.placeholder = 'Title';
  titleInput.value = bookmark?.title || '';
  titleInput.spellcheck = false;
  titleInput.readOnly = false;

  const urlInput = document.createElement('input');
  urlInput.type = 'text';
  urlInput.className = 'shelf-url-input';
  urlInput.placeholder = 'https://...';
  urlInput.value = bookmark?.href || '';
  urlInput.spellcheck = false;
  urlInput.readOnly = false;

  const removeBtn = document.createElement('button');
  removeBtn.className = 'shelf-remove-btn';
  removeBtn.textContent = '×';
  removeBtn.title = 'Remove';
  removeBtn.disabled = false;
  removeBtn.addEventListener('click', () => row.remove());

  row.appendChild(titleInput);
  row.appendChild(urlInput);
  row.appendChild(removeBtn);
  list.appendChild(row);

  if (!bookmark) titleInput.focus();
}

function _collectShelfBookmarks() {
  const rows = document.querySelectorAll('#shelf-list .shelf-row');
  const bookmarks = [];
  rows.forEach(row => {
    const title = row.querySelector('.shelf-title-input').value.trim();
    const href = row.querySelector('.shelf-url-input').value.trim();
    if (title || href) {
      bookmarks.push({ title: title || href, href: href || '#' });
    }
  });
  return bookmarks;
}

function toggleEditorMode() {
  const isShelf = _bmActiveTab === 'shelf';
  const editor = _bmGetEditor();
  const textarea = document.getElementById('config-textarea');
  const btn = document.getElementById('toggle-editor-btn');
  const shelfEditor = document.getElementById('shelf-list-editor');
  const inJsonMode = !textarea.classList.contains('hidden');

  if (inJsonMode) {
    try {
      const parsed = JSON.parse(textarea.value);
      if (!Array.isArray(parsed)) throw new Error('Not an array');
      textarea.classList.add('hidden');
      if (isShelf) {
        _renderShelfEditor(parsed);
      } else {
        _bmGroups = _bmGroupsFromBookmarks(parsed);
        renderGroupedEditor();
      }
      btn.textContent = 'View as JSON';
    } catch {
      showAlert('Invalid JSON format. Please fix any syntax errors before switching.', { type: 'error', title: 'Invalid JSON' });
    }
    return;
  }

  try {
    const bookmarks = isShelf ? _collectShelfBookmarks() : _bmCollectGroupedBookmarks();
    textarea.value = JSON.stringify(bookmarks, null, 2);
    textarea.readOnly = false;
    textarea.classList.remove('hidden');
    if (isShelf && shelfEditor) shelfEditor.classList.add('hidden');
    else if (editor) editor.classList.add('hidden');
    btn.textContent = 'View as Groups';
  } catch (err) {
    showAlert(err.message || 'Could not prepare bookmarks for JSON editing.', { type: 'error', title: 'Bookmarks need attention' });
  }
}

// ========================================
// Save
// ========================================
async function saveBookmarksFromModal() {
  const textarea = document.getElementById('config-textarea');
  const inJsonMode = textarea && !textarea.classList.contains('hidden');

  try {
    let bookmarks;
    if (inJsonMode) {
      bookmarks = JSON.parse(textarea.value);
      if (!Array.isArray(bookmarks)) throw new Error('Expected a JSON array');
    } else {
      bookmarks = _bmActiveTab === 'shelf' ? _collectShelfBookmarks() : _bmCollectGroupedBookmarks();
    }

    if (_bmActiveTab === 'shelf') {
      await saveShelfBookmarks(bookmarks);
    } else {
      await saveBookmarks(bookmarks);
    }

    if (typeof generateBookmarks === 'function') generateBookmarks();
    closeBookmarksModal();
  } catch (err) {
    if (err instanceof SyntaxError) {
      showAlert('Invalid JSON format. Please fix any syntax errors before saving.', { type: 'error', title: 'Invalid JSON' });
      return;
    }
    showAlert(err.message || 'Could not save bookmarks.', { type: 'error', title: 'Save Failed' });
  }
}
