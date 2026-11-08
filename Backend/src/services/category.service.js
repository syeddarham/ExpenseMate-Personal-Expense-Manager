const { NotFoundError, ValidationError } = require('../utils/http');

const DEFAULT_CATEGORIES = [
  { name: 'Food & Dining', icon: 'restaurant', color: '#F59E0B', isExpense: true },
  { name: 'Groceries', icon: 'shopping_cart', color: '#10B981', isExpense: true },
  { name: 'Transport', icon: 'directions_car', color: '#3B82F6', isExpense: true },
  { name: 'Bills & Utilities', icon: 'receipt_long', color: '#8B5CF6', isExpense: true },
  { name: 'Entertainment', icon: 'movie', color: '#EC4899', isExpense: true },
  { name: 'Health', icon: 'medical_services', color: '#EF4444', isExpense: true },
  { name: 'Shopping', icon: 'shopping_bag', color: '#F97316', isExpense: true },
  { name: 'Education', icon: 'school', color: '#0EA5E9', isExpense: true },
  { name: 'Travel', icon: 'flight', color: '#14B8A6', isExpense: true },
  { name: 'Salary / Income', icon: 'attach_money', color: '#059669', isExpense: false },
  { name: 'Freelance', icon: 'work', color: '#6366F1', isExpense: false },
  { name: 'Investments', icon: 'trending_up', color: '#06B6D4', isExpense: false },
  { name: 'Gifts', icon: 'card_giftcard', color: '#D946EF', isExpense: false },
];

class CategoryService {
  constructor({ categoryRepository, transactionRepository }) {
    this.categories = categoryRepository;
    this.transactions = transactionRepository;
  }

  /** Inserts the default categories. `db` lets registration run this inside its transaction. */
  async seedDefaults(userId, db = null) {
    const repo = db ? this.categories.withDb(db) : this.categories;
    for (const category of DEFAULT_CATEGORIES) {
      await repo.upsertDefault(userId, category);
    }
  }

  /** @param {'expense'|'income'|undefined} type */
  async list(userId, type) {
    if ((await this.categories.countForUser(userId)) === 0) {
      await this.seedDefaults(userId);
    }
    const isExpense = type === 'expense' ? true : type === 'income' ? false : undefined;
    return this.categories.listForUser(userId, { isExpense });
  }

  async create(userId, { name, icon, color, isExpense }) {
    await this.assertNameAvailable(userId, name);
    const id = await this.categories.create(userId, { name, icon, color, isExpense });
    return this.categories.findById(id);
  }

  async update(id, userId, { name, icon, color, isExpense }) {
    await this.getOwned(id, userId);
    await this.assertNameAvailable(userId, name, id);
    await this.categories.update(id, userId, { name, icon, color, isExpense });
    return this.categories.findById(id);
  }

  /** A category that still has transactions cannot be deleted. */
  async delete(id, userId) {
    const category = await this.getOwned(id, userId);
    const count = await this.transactions.countByCategory(id, userId);
    if (count > 0) {
      throw new ValidationError(
        `Cannot delete "${category.name}" because it is linked to ${count} transaction(s). ` +
          'Please reassign or delete those transactions first.',
        'CATEGORY_IN_USE',
      );
    }
    await this.categories.delete(id, userId);
  }

  async getOwned(id, userId) {
    const category = await this.categories.findOwned(id, userId);
    if (!category) throw new NotFoundError('Category not found');
    return category;
  }

  async assertNameAvailable(userId, name, excludeId = null) {
    if (await this.categories.findByName(userId, name, { excludeId })) {
      throw new ValidationError(`A category named "${name}" already exists`, 'DUPLICATE_CATEGORY');
    }
  }
}

module.exports = { CategoryService, DEFAULT_CATEGORIES };
