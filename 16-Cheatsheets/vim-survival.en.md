---
description: "Vim survival guide: quitting, saving, undo, modes and basic editing. Not about mastery — about fixing a config on a production server in 2 minutes and getting out."
tags:
  - Cheatsheet
  - Field Notes
---
# Vim Survival Guide

> *"How do I get out of Vim?"* — `:q!` (Enter)
> *"Oh god, what did I do?"* — `u` (undo)

This cheatsheet isn't about "become a Vim master" — it's about "fix a config
on a production server in 2 minutes and get out."

## 🚪 QUITTING (most important)

| Command | What it does |
|---|---|
| `:q` | Quit (if no changes) |
| `:q!` | **Force quit** (discard changes) |
| `:w` | Save |
| `:wq` or `:x` or `ZZ` | Save and quit |
| `:wa` | Save all open buffers |
| `:qa!` | Force quit everything |

## 🎮 Modes

```
NORMAL  ─┐ esc ┌─ INSERT (typing)
         │     │
         ├─────┼─ VISUAL (selecting)
         │     │
         └─────┴─ COMMAND (with `:`)
```

- **NORMAL** mode = navigation and commands (default)
- `Esc` always returns you to normal mode

## 🧭 Movement (in NORMAL mode)

```
        ↑
        k
    ←  h ↓  l →
        j
        ↓

w        next word
b        previous word
e        to end of word
0        start of line
^        first non-blank character on the line
$        end of line
gg       start of file
G        end of file
:42      go to line 42
H/M/L    top/middle/bottom of screen
Ctrl+u   half page up
Ctrl+d   half page down
Ctrl+f   full page down
Ctrl+b   full page up
%        matching bracket (), [], {}
```

## ✏️ Enter Insert mode

```
i        insert before cursor
a        insert after cursor (append)
I        insert at start of line
A        insert at end of line
o        new line below + insert
O        new line above + insert
```

## 🗑️ Delete / Cut

```
x        character under cursor
dd       delete line
3dd      delete 3 lines
d$       from cursor to end of line
dw       from cursor to end of word
diw      delete word (wherever the cursor is in it)
di"      delete inside "..." (content only)
da"      delete "..." including quotes
di(      delete inside (...)
dG       from cursor to end of file
dgg      from cursor to start of file
```

> 💡 **Every `d` command is pasteable** — Vim doesn't "delete," it "cuts."

## 📋 Copy / Paste

```
yy       copy line
3yy      3 lines
y$       copy from cursor to end of line
yw       word
y/foo    from cursor up to "foo"
p        paste AFTER cursor
P        paste BEFORE cursor
```

## ↩️ Undo / Redo

```
u            undo
Ctrl+r       redo
U            undo changes on the line
.            repeat last command (POWER!)
```

> 💎 **The `.` command** = Vim's most powerful weapon. Repeats whatever you just did.

## 🔍 Search

```
/foo       search forward
?foo       search backward
n          next match
N          previous
*          search for word under cursor (forward)
#          search for word under cursor (backward)

:noh       clear search highlight
```

## 🔄 Find / Replace

```
:s/old/new/          first match on the line
:s/old/new/g         all on the line
:%s/old/new/g        all in the file
:%s/old/new/gc       ask before each replace
:%s/\<old\>/new/g    word-boundary (whole words only)

# With a range (from line 10 to 20)
:10,20s/old/new/g

# After a visual selection:
:'<,'>s/old/new/g
```

## 👀 Visual mode (selecting)

```
v        select character by character
V        select line
Ctrl+v   block (column) select — POWER mode

# After selecting:
y        copy
d        delete
>        indent right
<        indent left
=        auto-indent
:        run a command on the selected lines
```

## 📚 Buffer / Window / Tab

```bash
:e <FILE>       open file
:bn             next buffer
:bp             previous buffer
:bd             close buffer
:ls             buffer list

:split          split screen horizontally
:vsplit         split screen vertically
Ctrl+w h/j/k/l  move between windows
Ctrl+w =        equalize windows
Ctrl+w q        close window

:tabnew <FILE>  new tab
:tabnext        next tab (gt)
:tabprev        previous tab (gT)
```

## 💾 Saving & Emergency

```
:w                  save
:w <FILE>           save as another name
:w !sudo tee %      forgot you needed sudo (ROOT operation)
:e!                 revert file to the version on disk
:earlier 10m        undo the last 10 minutes
:later 10m          redo again
```

## 🎨 Visual settings

```
:set number             line numbers (short: :set nu)
:set relativenumber     relative (short: :set rnu)
:set list               show invisible characters
:set hlsearch           search highlight
:set ignorecase         case-insensitive search
:set smartcase          case-sensitive when you type uppercase
:set paste              disables auto-indent (for pasting)
:syntax on              syntax highlighting

:colorscheme desert     theme
```

## 📐 Indent / Format

```
>>          indent line 1 to the right
<<          1 indent to the left
==          auto-indent the line
gg=G        indent the whole file
gqq         wrap line to 80 chars

:set tabstop=2 shiftwidth=2 expandtab
```

## 🪄 Practical combinations

```
ciw "new"           delete word + insert "new"
ci"  "new"          replace inside "..."
df.                 delete from cursor to next period
yy p                duplicate line
:%!sort             pipe the whole file through sort
:%!jq .             format the whole file with jq
:r !date            insert `date` output at current position
:r <FILE>           insert the contents of another file
ggVG                select the whole file
```

## 🆘 Emergency scenarios

| Problem | Solution |
|---|---|
| "I can't quit!" | `Esc` `:q!` `Enter` |
| "I did something wrong" | `u` (undo), `u` again |
| "No ESC key" (in terminal) | `Ctrl+[` is the same thing |
| "Forgot sudo, can't save" | `:w !sudo tee %` then `:q!` |
| "I want line numbers" | `:set nu` |
| "Discard all changes, start over" | `:e!` |
| "It says read-only" | `:set noreadonly` or `:w!` |
| "Swap file warning" | someone else has it open; `D` (delete swap) or `R` (read-only) |
| "What did I do in the last hour?" | `:earlier 1h` |
| "Life without Vim is possible" | `nano <FILE>` 😉 |

## 🔌 .vimrc minimum

```vim
" ~/.vimrc — minimum for a production server
set nocompatible
set number
set relativenumber
set tabstop=2 shiftwidth=2 expandtab
set autoindent smartindent
set ignorecase smartcase
set hlsearch incsearch
set mouse=a
set clipboard=unnamedplus
syntax on

" Sudo save (shortcut)
cmap w!! w !sudo tee > /dev/null %
```
