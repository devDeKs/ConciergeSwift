/**
 * InstallmentEngine Service
 * 
 * A robust backend service for calculating and managing installment payments
 * with proper date logic for credit cards and other payment methods.
 */

// ============================================
// Types
// ============================================

export type PaymentMethod = 'credit_card' | 'boleto' | 'pix'

export interface InstallmentInput {
    totalAmount: number
    numberOfInstallments: number
    startDate: Date
    paymentMethod: PaymentMethod
    creditCardClosingDay?: number
    creditCardDueDay?: number
    description: string
    category: string
}

export interface InstallmentOutput {
    installmentNumber: number
    totalInstallments: number
    amount: number
    dueDate: string // ISO format YYYY-MM-DD
    description: string
    category: string
    status: 'pending' | 'paid'
    paymentMethod: PaymentMethod
}

// ============================================
// InstallmentEngine Class
// ============================================

export class InstallmentEngine {
    /**
     * Generates an array of installment objects ready for database insertion
     */
    generateInstallments(input: InstallmentInput): InstallmentOutput[] {
        // Validate input
        this.validateInput(input)

        const {
            totalAmount,
            numberOfInstallments,
            startDate,
            paymentMethod,
            creditCardClosingDay,
            creditCardDueDay,
            description,
            category
        } = input

        // Calculate amount per installment (handle rounding)
        const baseAmount = Math.floor((totalAmount / numberOfInstallments) * 100) / 100
        const remainder = Math.round((totalAmount - (baseAmount * numberOfInstallments)) * 100) / 100

        const installments: InstallmentOutput[] = []

        for (let i = 0; i < numberOfInstallments; i++) {
            // Handle rounding - add remainder to last installment
            const amount = i === numberOfInstallments - 1
                ? baseAmount + remainder
                : baseAmount

            // Calculate due date based on payment method
            const dueDate = paymentMethod === 'credit_card'
                ? this.calculateCreditCardDueDate(startDate, i, creditCardClosingDay!, creditCardDueDay!)
                : this.calculateMonthlyDueDate(startDate, i)

            installments.push({
                installmentNumber: i + 1,
                totalInstallments: numberOfInstallments,
                amount: Math.round(amount * 100) / 100,
                dueDate: this.formatDate(dueDate),
                description: `Parcela ${i + 1}/${numberOfInstallments} - ${description}`,
                category,
                status: 'pending',
                paymentMethod
            })
        }

        return installments
    }

    /**
     * Validates input data before processing
     */
    private validateInput(input: InstallmentInput): void {
        if (input.totalAmount <= 0) {
            throw new Error('Total amount must be positive')
        }

        if (input.numberOfInstallments < 1) {
            throw new Error('Number of installments must be at least 1')
        }

        if (!input.description || input.description.trim() === '') {
            throw new Error('Description is required')
        }

        if (input.paymentMethod === 'credit_card') {
            if (!input.creditCardClosingDay || !input.creditCardDueDay) {
                throw new Error('Credit card requires closing day and due day')
            }
        }
    }

    /**
     * Calculates due date for boleto/pix payments (monthly interval)
     */
    private calculateMonthlyDueDate(startDate: Date, installmentIndex: number): Date {
        // Use UTC methods to avoid timezone issues
        const year = startDate.getUTCFullYear()
        const month = startDate.getUTCMonth() + installmentIndex
        const day = startDate.getUTCDate()

        // Calculate target year and month
        const targetYear = year + Math.floor(month / 12)
        const targetMonth = month % 12

        // Get the last day of the target month
        const lastDayOfMonth = new Date(Date.UTC(targetYear, targetMonth + 1, 0)).getUTCDate()

        // Use original day or last day of month if original day doesn't exist
        const adjustedDay = Math.min(day, lastDayOfMonth)

        return new Date(Date.UTC(targetYear, targetMonth, adjustedDay))
    }

    /**
     * Calculates due date for credit card payments based on billing cycle
     */
    private calculateCreditCardDueDate(
        purchaseDate: Date,
        installmentIndex: number,
        closingDay: number,
        dueDay: number
    ): Date {
        // Use UTC methods to avoid timezone issues
        const purchaseDay = purchaseDate.getUTCDate()
        let purchaseMonth = purchaseDate.getUTCMonth()
        let purchaseYear = purchaseDate.getUTCFullYear()

        // Determine which billing cycle this falls into
        // If purchase is ON or BEFORE closing day, it goes to current invoice
        // If purchase is AFTER closing day, it goes to next month's invoice
        let invoiceMonth: number
        let invoiceYear: number

        if (purchaseDay <= closingDay) {
            // Goes to current month's closing, due next month
            invoiceMonth = purchaseMonth + 1
            invoiceYear = purchaseYear
        } else {
            // Goes to next month's closing, due the month after
            invoiceMonth = purchaseMonth + 2
            invoiceYear = purchaseYear
        }

        // Add installment offset
        invoiceMonth += installmentIndex

        // Normalize month/year
        while (invoiceMonth > 11) {
            invoiceMonth -= 12
            invoiceYear++
        }

        // Get last day of invoice month to handle edge cases
        const lastDayOfMonth = new Date(Date.UTC(invoiceYear, invoiceMonth + 1, 0)).getUTCDate()
        const adjustedDueDay = Math.min(dueDay, lastDayOfMonth)

        return new Date(Date.UTC(invoiceYear, invoiceMonth, adjustedDueDay))
    }

    /**
     * Formats a Date object to YYYY-MM-DD string
     */
    private formatDate(date: Date): string {
        const year = date.getUTCFullYear()
        const month = String(date.getUTCMonth() + 1).padStart(2, '0')
        const day = String(date.getUTCDate()).padStart(2, '0')
        return `${year}-${month}-${day}`
    }
}

// ============================================
// Singleton instance for convenience
// ============================================

export const installmentEngine = new InstallmentEngine()

// ============================================
// Helper function for direct use
// ============================================

export function generateInstallments(input: InstallmentInput): InstallmentOutput[] {
    return installmentEngine.generateInstallments(input)
}
