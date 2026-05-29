# frozen_string_literal: true

# Handles the expenses of the application
class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[show update destroy]

  # GET /expenses
  # @return [void]
  def index
    @expenses = policy_scope(Expense)
    authorize Expense

    render json: @expenses
  end

  # GET /expenses/1
  # @return [void]
  def show
    authorize @expense
    render json: @expense, serializer: ExpenseSerializer
  end

  # POST /expenses
  # @return [void]
  def create
    @expense = Expense.new(expense_params)
    @expense.user_id = current_user.id unless current_user.staff?

    authorize @expense

    if @expense.save
      render json: @expense, serializer: ExpenseSerializer, status: :created
    else
      render json: @expense.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /expenses/1
  # @return [void]
  def update
    authorize @expense
    if @expense.update(expense_params)
      render json: @expense, serializer: ExpenseSerializer, status: :ok
    else
      render json: @expense.errors, status: :unprocessable_entity
    end
  end

  # DELETE /expenses/1
  # @return [void]
  def destroy
    authorize @expense
    @expense.destroy
    render json: { message: "Expense was successfully destroyed." }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # @return [void]
  def set_expense
    @expense = policy_scope(Expense).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # @return [void]
  def expense_params
    params.require(:expense).permit(:residential_id, :user_id, :account, :department, :expense_type, :comments, :amount)
  end
end
