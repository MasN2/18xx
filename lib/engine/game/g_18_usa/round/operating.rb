# frozen_string_literal: true

require_relative '../../g_1817/round/operating'

module Engine
  module Game
    module G18USA
      module Round
        class Operating < G1817::Round::Operating
          def setup
            super
            @train_export_triggered = false
          end

          def finished?
            return false unless super

            unless @train_export_triggered
              @game.export_train
              @train_export_triggered = true
            end

            super
          end

          def pay_interest!(entity)
            @cash_crisis_due_to_interest = nil
            return if @paid_loans[entity]
            return unless step_passed?(G18USA::Step::BuyTrain)

            @paid_loans[entity] = true
            return if @game.interest_owed(entity).zero?

            bank = @game.bank
            owed = @game.interest_owed(entity)
            if owed.positive?
              @game.log_interest_payment(entity, owed)
              entity.spend(owed, bank)
            end
            return unless entity.cash.negative?

            owed_fmt = @game.format_currency(-entity.cash)

            owner = entity.owner
            @game.liquidate!(entity)
            transferred = ''

            @log << "#{entity.name} is #{owed_fmt} short on interest and goes into liquidation#{transferred}"

            owner.spend(-entity.cash, entity, check_cash: false)
            @cash_crisis_due_to_interest = entity
            @log << "#{owner.name} pays #{owed_fmt} shortfall on interest"
          end
        end
      end
    end
  end
end
