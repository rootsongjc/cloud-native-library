---
# A section created with the Portfolio widget.
# This section displays content from `content/project/`.
# See https://wowchemy.com/docs/widget/portfolio/
widget: portfolio

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 30

title: '书目列表'
subtitle: '开源电子书&出版物'

content:
  # Page type to display. E.g. project.
  page_type: publication
  filters:
    folders:
      - book
  # Default filter index (e.g. 0 corresponds to the first `filter_button` instance below).
  filter_default: 0

  # Filter toolbar (optional).
  # Add or remove as many filters (`filter_button` instances) as you like.
  # To show all items, set `tag` to "*".
  # To filter by a specific tag, set `tag` to an existing tag name.
  # To remove the toolbar, delete the entire `filter_button` block.
  filter_button:
    - name: All
      tag: '*'
    - name: Handbook系列
      tag: Handbook系列
    - name: 出版物
      tag: 出版物
    - name: 翻译电子书
      tag: 翻译电子书

design:
  columns: '1'
  view: masonry
  flip_alt_rows: false
  background-color: rgb(247, 247, 247);
---
