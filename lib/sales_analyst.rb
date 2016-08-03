require_relative "../lib/sales_engine"
require "pry"

class SalesAnalyst
  attr_reader :se, :avg_inv_per_day

  def initialize(sales_engine)
    @se = sales_engine
  end

  def all_merchant
    se.merchants.all
  end

  def all_items
    se.items.all
  end

  def all_invoices
    se.invoices.all
  end

  def average_items_per_merchant
    ((se.items.all.count)/(all_merchant.count.to_f)).round(2)
  end

  def collct_of_itms_cnts
    collection  = all_merchant.map do |merchant|
      merchant.items.count
    end
    collection
  end

  def items_qty
    collct_of_itms_cnts.count
  end

  def average_items_per_merchant_standard_deviation
    avg_itm_p_mrchnt = average_items_per_merchant
    merchant_deviation_calculator(collct_of_itms_cnts, avg_itm_p_mrchnt)
  end

  def merchant_deviation_calculator(collct_of_itms_cnts, avg_itm_p_mrchnt)
    pre_deviation = (collct_of_itms_cnts.reduce(0) do |accounter, average_num|
      accounter + ((average_num - avg_itm_p_mrchnt) ** 2)
    end)/(items_qty - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def merchants_with_high_item_count
    high_count = average_items_per_merchant_standard_deviation +
    average_items_per_merchant
    all_merchant.find_all do |merchant|
      merchant.items.count > high_count
    end
  end

  def average_item_price_for_merchant(merchant_id)
    prc_per_unit = se.merchants.find_by_id(merchant_id).items.map(&:unit_price)
    pre_return = (prc_per_unit.reduce(:+)/prc_per_unit.size)
    pre_return.round(2)
  end

  def average_average_price_per_merchant
    sum_of_averages = all_merchant.reduce(0) do |sum, merchant|
      sum + average_item_price_for_merchant(merchant.id)
    end
    outcome = sum_of_averages / all_merchant.count
    outcome.floor(2)
  end

  def average_item_price_standard_deviation
    avg_avg_p_merchant = average_average_price_per_merchant
    items = all_items.map(&:unit_price)
    pre_deviation = (items.reduce(0) do |accounter, avg_num|
      accounter + ((avg_num - avg_avg_p_merchant) ** 2)
    end)/(items.count - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def golden_items
    deviation = (average_item_price_standard_deviation * 2)
    golden_price = deviation + average_average_price_per_merchant
    all_items.find_all do |item|
      item.unit_price > golden_price
    end
  end

  def average_invoices_per_merchant
    ((all_invoices.count)/(all_merchant.count.to_f)).round(2)
  end

  def collct_of_invs_cnts
    collection  = all_merchant.map do |merchant|
      merchant.invoices.count
    end
    collection
  end

  def inv_qty
    collct_of_invs_cnts.count
  end

  def average_invoices_per_merchant_standard_deviation
    avg_inv_p_mrchnt = average_invoices_per_merchant
    invoice_deviation_calculator(collct_of_invs_cnts, avg_inv_p_mrchnt)
  end

  def invoice_deviation_calculator(collct_of_invs_cnts, average_invs_p_merchant)
    pre_deviation = (collct_of_invs_cnts.reduce(0) do |accounter, average_num|
      accounter + ((average_num - average_invs_p_merchant) ** 2)
    end)/(inv_qty - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def top_merchants_by_invoice_count
    deviation = (average_invoices_per_merchant_standard_deviation * 2)
    high_inv_count = deviation + average_invoices_per_merchant
    all_merchant.find_all do |merchant|
      merchant.invoices.count > high_inv_count
    end
  end

  def bottom_merchants_by_invoice_count
    deviation = (average_invoices_per_merchant_standard_deviation * 2)
    lower_inv_count = average_invoices_per_merchant - deviation
    all_merchant.find_all do |merchant|
      merchant.invoices.count < lower_inv_count
    end
  end

  def formatting_inv_cnt_per_day
    all_invoices.reduce(Hash.new(0)) do |result, invoices|
      invoice_day = invoices.created_at.strftime("%A")
      result[invoice_day] += 1
      result
    end
  end

  def top_day_deviation_calculator
    @avg_inv_per_day = (all_invoices.count / 7).to_f
    day_totals = formatting_inv_cnt_per_day.values
    pre_deviation = (day_totals.reduce(0) do |sum, avg_num|
      sum + ((avg_num - avg_inv_per_day) ** 2)
    end)/(day_totals.count - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def top_days_by_invoice_count
    deviation = top_day_deviation_calculator
    most_selling_day = formatting_inv_cnt_per_day.find_all do |wkday, count|
      count > (deviation + avg_inv_per_day)
    end
    most_selling_day.map {|wkday, count| wkday}
  end

  def invoice_status(status)
    invoices = se.invoices.find_all_by_status(status)
    result = ((invoices.count.to_f)/(all_invoices.count))
    (result * 100).round(2)
  end

  def total_revenue_by_date(date)
    invoices = se.invoices.find_all_by_date(date)
    inv_ids = invoices.map {|invoice| invoice.id}
    finding_total_revenue_by_date(invoices, inv_ids)
  end

  def finding_total_revenue_by_date(invoices, inv_ids)
    inv_items = se.invoice_items
    all_inv_itms = inv_ids.map {|id| inv_items.
      find_all_by_invoice_id(id)}.flatten
    result = all_inv_itms.map do |inv_itms|
      inv_itms.quantity * inv_itms.unit_price
    end
    result.reduce(:+)
  end

  def ranking_merchants_by_revenue
      all_merchant.sort_by do |merchant|
      merchant.revenue
    end
  end

  # def removing_nils(ranking)
  #   ranking.delete_if do |merchant|
  #     merchant.revenue == 0.0
  #   end
  # end

  def top_revenue_earners(number = 20)
    ranking_merchants_by_revenue[0..number - 1]
  end

end
