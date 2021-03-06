module SalesAnalystAssistant

  def all_merchant
    se.merchants.all
  end

  def all_items
    se.items.all
  end

  def all_invoices
    se.invoices.all
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

  def merchant_deviation_calculator(collct_of_itms_cnts, avg_itm_p_mrchnt)
    pre_deviation = (collct_of_itms_cnts.reduce(0) do |accounter, average_num|
      accounter + ((average_num - avg_itm_p_mrchnt) ** 2)
    end)/(items_qty - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def average_item_price_standard_deviation
    avg_avg_p_merchant = average_average_price_per_merchant
    items = all_items.map(&:unit_price)
    pre_deviation = (items.reduce(0) do |accounter, avg_num|
      accounter + ((avg_num - avg_avg_p_merchant) ** 2)
    end)/(items.count - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def formatting_inv_cnt_per_day
    all_invoices.reduce(Hash.new(0)) do |result, invoices|
      invoice_day = invoices.created_at.strftime("%A")
      result[invoice_day] += 1
      result
    end
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

  def invoice_deviation_calculator(collct_of_invs_cnts, average_invs_p_merchant)
    pre_deviation = (collct_of_invs_cnts.reduce(0) do |accounter, average_num|
      accounter + ((average_num - average_invs_p_merchant) ** 2)
    end)/(inv_qty - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def top_day_deviation_calculator
    @avg_inv_per_day = (all_invoices.count / 7).to_f
    day_totals = formatting_inv_cnt_per_day.values
    pre_deviation = (day_totals.reduce(0) do |sum, avg_num|
      sum + ((avg_num - avg_inv_per_day) ** 2)
    end)/(day_totals.count - 1).to_f
    Math.sqrt(pre_deviation).round(2)
  end

  def finding_total_revenue_by_date(invoices, inv_ids)
    inv_items = se.invoice_items
    all_inv_itms = inv_ids.map {|id| inv_items.
      find_all_by_invoice_id(id)}.flatten
    returning_revenue_date(inv_items, all_inv_itms)
  end

  def returning_revenue_date(inv_items, all_inv_itms)
    result = all_inv_itms.map do |inv_itms|
      inv_itms.quantity * inv_itms.unit_price
    end
    result.reduce(:+)
  end

  def merchant_items_sold(invoice_items)
    invoice_items.reduce({}) do |hash, invoice_item|
      hash[invoice_item.item_id] = 0 if hash[invoice_item.item_id].nil?
      hash[invoice_item.item_id] += invoice_item.quantity
      hash
    end
  end

  def invoice_price_vs_item_unit_price(invoice_item_id)
    invoice_item = se.invoice_items.find_by_id(invoice_item_id)
    item = se.items.find_by_id(invoice_item.item_id)
    (invoice_item.unit_price / item.unit_price - 1).round(2).to_f
  end

  def invoice_revenue(invoice_id)
    invoice = se.invoices.find_by_id(invoice_id)
    return 0 if !invoice.is_paid_in_full?
    invoice_items = se.invoice_items.find_all_by_invoice_id(invoice.id)
    invoice_items.reduce(0) do |sum, invoice_item|
      sum+invoice_item.quantity*item_by_invoice_item(invoice_item).unit_price
    end.to_f
  end

  def item_by_invoice_item(invoice_item)
    se.items.find_by_id(invoice_item.item_id)
  end

  def invoice_total_vs_revenue_by_id(invoice_id)
    invoice = se.invoices.find_by_id(invoice_id)
    return 0 if !invoice.is_paid_in_full?
    (invoice.total / invoice_revenue(invoice.id) - 1).to_f.round(2)
  end

  def merchant_average_discount(merchant_id)
    merchant = se.merchants.find_by_id(merchant_id)
    ttl_disc_given = merchant.invoices.reduce(0) do |sum, invoice|
      sum + invoice_total_vs_revenue_by_id(invoice.id)
    end
    return 0 if merchant.invoices.empty?
    (ttl_disc_given / merchant.invoices.length).round(2)
  end

  def merchants_average_average_discount
    total_discount = se.merchants.all.reduce(0) do |sum, merchant|
      sum + merchant_average_discount(merchant.id)
    end
    (total_discount / se.merchants.all.length).round(2)
  end

end
