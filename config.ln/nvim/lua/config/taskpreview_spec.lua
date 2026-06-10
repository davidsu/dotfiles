-- Tests for config/taskpreview.lua
-- Run with: :PlenaryBustedFile %

local preview = require('config.taskpreview')._test
local eq = assert.are.equal

local root = '/Users/me/projects/app'

describe('taskpreview', function()
  describe('toLocalFileUrl', function()
    it('strips the line fragment', function()
      eq('file:///Users/me/projects/app/frontend/a.ts',
        preview.toLocalFileUrl(root, '/frontend/a.ts#L41'))
    end)

    it('strips a range fragment', function()
      eq('file:///Users/me/projects/app/backend/b.py',
        preview.toLocalFileUrl(root, '/backend/b.py#L14-L22'))
    end)

    it('strips a query before the fragment', function()
      eq('file:///Users/me/projects/app/suss-tasks/foo.md',
        preview.toLocalFileUrl(root, '/suss-tasks/foo.md?plain=1#L14'))
    end)
  end)

  describe('rewriteRootRelativeLinks', function()
    it('rewrites an inline code link', function()
      eq('see [store](file:///Users/me/projects/app/frontend/a.ts) here',
        preview.rewriteRootRelativeLinks('see [store](/frontend/a.ts#L41) here', root))
    end)

    it('rewrites multiple inline links on one line', function()
      eq('[a](file:///Users/me/projects/app/x.ts) and [b](file:///Users/me/projects/app/y.ts)',
        preview.rewriteRootRelativeLinks('[a](/x.ts#L1) and [b](/y.ts#L2)', root))
    end)

    it('rewrites a reference definition', function()
      eq('[p1]: file:///Users/me/projects/app/frontend/a.ts',
        preview.rewriteRootRelativeLinks('[p1]: /frontend/a.ts#L90', root))
    end)

    it('leaves external links untouched', function()
      eq('[docs](https://example.com/page#L1)',
        preview.rewriteRootRelativeLinks('[docs](https://example.com/page#L1)', root))
    end)

    it('leaves in-page anchors untouched', function()
      eq('[top](#one-source-of-truth)',
        preview.rewriteRootRelativeLinks('[top](#one-source-of-truth)', root))
    end)

    it('leaves a reference-style usage token untouched', function()
      eq('| P1 | [reduceSlot][p1] recomputes url |',
        preview.rewriteRootRelativeLinks('| P1 | [reduceSlot][p1] recomputes url |', root))
    end)
  end)

  describe('rewriteCodeLinks', function()
    it('rewrites every line in the list', function()
      local lines = {
        '[a](/x.ts#L1)',
        'plain text',
        '[p1]: /y.ts#L2',
      }
      local result = preview.rewriteCodeLinks(lines, root)
      eq('[a](file:///Users/me/projects/app/x.ts)', result[1])
      eq('plain text', result[2])
      eq('[p1]: file:///Users/me/projects/app/y.ts', result[3])
    end)
  end)
end)
