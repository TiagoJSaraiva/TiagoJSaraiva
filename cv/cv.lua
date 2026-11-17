-- Filtro do Pandoc que dá ao CV o visual final no PDF.

local function latex(s) return pandoc.RawInline('latex', s) end
local function latexb(s) return pandoc.RawBlock('latex', s) end

-- Ícones (imagens dentro de icons/): altura de uma linha, alinhados ao texto
function Image(img)
  if img.src:match('^icons/') then
    -- usa a versão PDF do ícone (gerada a partir do SVG), que o LaTeX lê sem conversores extras
    local pdf = img.src:gsub('%.svg$', '.pdf')
    local f = io.open(pdf, 'r')
    if f then f:close(); img.src = pdf end
    img.attributes.height = '0.95em'
    img.caption = {}
    return { latex('\\raisebox{-0.17em}{'), img, latex('}') }
  end
end

-- <span class="direita">texto</span> -> texto alinhado à direita da linha
function Span(el)
  if el.classes:includes('direita') then
    local out = { latex('\\hfill{\\color{cinza}') }
    for _, i in ipairs(el.content) do table.insert(out, i) end
    table.insert(out, latex('}'))
    return out
  end
end

-- Título (#) = nome em destaque; ele e o parágrafo logo abaixo (contatos) ficam alinhados à esquerda
function Pandoc(doc)
  local blocks = pandoc.List()
  local alinhar_proximo = false
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 1 then
      blocks:insert(latexb('\\begin{flushleft}{\\Huge\\bfseries\\color{azul} '))
      blocks:insert(pandoc.Plain(b.content))
      blocks:insert(latexb('}\\end{flushleft}\\vspace{0.2em}'))
      alinhar_proximo = true
    elseif alinhar_proximo and b.t == 'Para' then
      blocks:insert(latexb('\\begin{flushleft}\\small'))
      blocks:insert(b)
      blocks:insert(latexb('\\end{flushleft}'))
      alinhar_proximo = false
    elseif b.t == 'Header' then
      -- ## vira \section, ### vira \subsection, #### vira \subsubsection
      b.level = b.level - 1
      blocks:insert(b)
    else
      blocks:insert(b)
    end
  end
  doc.blocks = blocks
  return doc
end

-- &emsp; (espaço largo usado entre os contatos) -> \quad no LaTeX
function Str(s)
  if s.text:find('\u{2003}') then
    local out = {}
    for parte, sep in (s.text .. '\u{2003}'):gmatch('(.-)(\u{2003})') do
      if parte ~= '' then table.insert(out, pandoc.Str(parte)) end
      table.insert(out, latex('\\quad '))
    end
    table.remove(out)
    return out
  end
end
