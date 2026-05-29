# frozen_string_literal: true

class NormalizePaymentStatuses < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE payments
      SET status = 'Pendiente'
      WHERE status IN ('pending', '0') OR status IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE payments
      SET status = 'Pagado'
      WHERE status IN ('1', 'paid')
    SQL
  end

  def down
    # Legacy values cannot be restored reliably.
  end
end
