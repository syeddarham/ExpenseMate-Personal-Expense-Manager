const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { categoryToJson } = require('../utils/serializers');

const COLOR_RE = /^#[0-9a-fA-F]{6}$/;

/** HTTP layer for /api/categories. */
function createCategoryController({ categoryService }) {
  return {
    list: asyncHandler(async (req, res) => {
      const type = req.query.type === 'expense' || req.query.type === 'income' ? req.query.type : undefined;
      const categories = await categoryService.list(req.user.id, type);
      res.json({ categories: categories.map(categoryToJson) });
    }),

    create: asyncHandler(async (req, res) => {
      const input = parseCategoryBody(req.body);
      const category = await categoryService.create(req.user.id, input);
      res.status(201).json({ category: categoryToJson(category) });
    }),

    update: asyncHandler(async (req, res) => {
      const v = new Validator();
      const id = v.id(req.params.id, 'id');
      v.assert();
      const input = parseCategoryBody(req.body);
      res.json({ category: categoryToJson(await categoryService.update(id, req.user.id, input)) });
    }),

    remove: asyncHandler(async (req, res) => {
      const v = new Validator();
      const id = v.id(req.params.id, 'id');
      v.assert();
      await categoryService.delete(id, req.user.id);
      res.json({ message: 'Category deleted successfully' });
    }),
  };
}

function parseCategoryBody(body) {
  const v = new Validator();
  const name = v.string(body.name, 'name', { min: 1, max: 80 });
  const icon = v.string(body.icon || 'category', 'icon', { max: 50 });
  const color = body.color || '#10B981';
  if (!COLOR_RE.test(color)) v.fail('color', 'color must be a hex value like #10B981');
  const isExpense = body.is_expense === undefined ? true : !!body.is_expense;
  v.assert();
  return { name, icon, color, isExpense };
}

module.exports = { createCategoryController };
