/**
 * InstallmentEngine Unit Tests
 * 
 * Following TDD: These tests are written BEFORE the implementation.
 * The InstallmentEngine service must pass all these tests.
 */

import {
    InstallmentEngine,
    InstallmentInput,
    InstallmentOutput,
    PaymentMethod
} from '../installmentEngine'

describe('InstallmentEngine', () => {
    let engine: InstallmentEngine

    beforeEach(() => {
        engine = new InstallmentEngine()
    })

    // ============================================
    // 1. BASIC INSTALLMENT GENERATION
    // ============================================
    describe('Basic Installment Generation', () => {
        it('should generate correct number of installments', () => {
            const input: InstallmentInput = {
                totalAmount: 1200,
                numberOfInstallments: 12,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'iPhone 15',
                category: 'Eletrônicos'
            }

            const result = engine.generateInstallments(input)

            expect(result).toHaveLength(12)
        })

        it('should calculate correct amount per installment', () => {
            const input: InstallmentInput = {
                totalAmount: 1200,
                numberOfInstallments: 12,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'iPhone 15',
                category: 'Eletrônicos'
            }

            const result = engine.generateInstallments(input)

            // Each installment should be R$100
            result.forEach(installment => {
                expect(installment.amount).toBe(100)
            })
        })

        it('should handle amounts that do not divide evenly', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 3,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            // Total should equal original amount (handles rounding)
            const total = result.reduce((sum, i) => sum + i.amount, 0)
            expect(total).toBeCloseTo(100, 2)
        })

        it('should generate correct installment numbers', () => {
            const input: InstallmentInput = {
                totalAmount: 600,
                numberOfInstallments: 6,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            result.forEach((installment, index) => {
                expect(installment.installmentNumber).toBe(index + 1)
                expect(installment.totalInstallments).toBe(6)
            })
        })

        it('should generate correct descriptions', () => {
            const input: InstallmentInput = {
                totalAmount: 300,
                numberOfInstallments: 3,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Geladeira',
                category: 'Eletrodomésticos'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].description).toBe('Parcela 1/3 - Geladeira')
            expect(result[1].description).toBe('Parcela 2/3 - Geladeira')
            expect(result[2].description).toBe('Parcela 3/3 - Geladeira')
        })
    })

    // ============================================
    // 2. MONTHLY DUE DATE CALCULATION (BOLETO/PIX)
    // ============================================
    describe('Monthly Due Date Calculation', () => {
        it('should generate consecutive monthly due dates', () => {
            const input: InstallmentInput = {
                totalAmount: 300,
                numberOfInstallments: 3,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].dueDate).toBe('2025-01-15')
            expect(result[1].dueDate).toBe('2025-02-15')
            expect(result[2].dueDate).toBe('2025-03-15')
        })

        it('should handle year boundary (December → January)', () => {
            const input: InstallmentInput = {
                totalAmount: 300,
                numberOfInstallments: 3,
                startDate: new Date('2025-11-20'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].dueDate).toBe('2025-11-20')
            expect(result[1].dueDate).toBe('2025-12-20')
            expect(result[2].dueDate).toBe('2026-01-20')
        })

        it('should adjust day 31 for months with fewer days', () => {
            const input: InstallmentInput = {
                totalAmount: 200,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-31'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].dueDate).toBe('2025-01-31')
            // February doesn't have 31 days, should be adjusted to last day
            expect(result[1].dueDate).toBe('2025-02-28')
        })

        it('should handle leap year February correctly', () => {
            const input: InstallmentInput = {
                totalAmount: 200,
                numberOfInstallments: 2,
                startDate: new Date('2024-01-29'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].dueDate).toBe('2024-01-29')
            // 2024 is a leap year, February has 29 days
            expect(result[1].dueDate).toBe('2024-02-29')
        })

        it('should handle non-leap year February correctly', () => {
            const input: InstallmentInput = {
                totalAmount: 200,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-29'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].dueDate).toBe('2025-01-29')
            // 2025 is not a leap year, February has 28 days
            expect(result[1].dueDate).toBe('2025-02-28')
        })
    })

    // ============================================
    // 3. CREDIT CARD BILLING CYCLE LOGIC
    // ============================================
    describe('Credit Card Billing Cycle', () => {
        it('should adjust due date based on closing day', () => {
            const input: InstallmentInput = {
                totalAmount: 300,
                numberOfInstallments: 3,
                startDate: new Date('2025-01-03'), // Before closing day 5
                paymentMethod: 'credit_card',
                creditCardClosingDay: 5,
                creditCardDueDay: 15,
                description: 'Compra',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            // Purchase on Jan 3 (before Jan 5 closing), closes on Jan 5, due Feb 15
            expect(result[0].dueDate).toBe('2025-02-15')
            expect(result[1].dueDate).toBe('2025-03-15')
            expect(result[2].dueDate).toBe('2025-04-15')
        })

        it('should go to next billing cycle if purchase is after closing', () => {
            const input: InstallmentInput = {
                totalAmount: 200,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-06'), // After closing day 5
                paymentMethod: 'credit_card',
                creditCardClosingDay: 5,
                creditCardDueDay: 15,
                description: 'Compra',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            // Purchase on Jan 6 (after Jan 5 close), goes to Mar 15 invoice
            expect(result[0].dueDate).toBe('2025-03-15')
            expect(result[1].dueDate).toBe('2025-04-15')
        })

        it('should handle same-day purchase on closing day', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 1,
                startDate: new Date('2025-01-05'), // Same as closing day
                paymentMethod: 'credit_card',
                creditCardClosingDay: 5,
                creditCardDueDay: 15,
                description: 'Compra',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            // Purchase on closing day should go to current invoice
            expect(result[0].dueDate).toBe('2025-02-15')
        })
    })

    // ============================================
    // 4. INPUT VALIDATION
    // ============================================
    describe('Input Validation', () => {
        it('should throw error for negative total amount', () => {
            const input: InstallmentInput = {
                totalAmount: -100,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            expect(() => engine.generateInstallments(input)).toThrow('Total amount must be positive')
        })

        it('should throw error for zero total amount', () => {
            const input: InstallmentInput = {
                totalAmount: 0,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            expect(() => engine.generateInstallments(input)).toThrow('Total amount must be positive')
        })

        it('should throw error for zero installments', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 0,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            expect(() => engine.generateInstallments(input)).toThrow('Number of installments must be at least 1')
        })

        it('should throw error for negative installments', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: -5,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            expect(() => engine.generateInstallments(input)).toThrow('Number of installments must be at least 1')
        })

        it('should throw error for credit card without closing day', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'credit_card',
                description: 'Produto',
                category: 'Outros'
            }

            expect(() => engine.generateInstallments(input)).toThrow('Credit card requires closing day and due day')
        })

        it('should throw error for empty description', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 2,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: '',
                category: 'Outros'
            }

            expect(() => engine.generateInstallments(input)).toThrow('Description is required')
        })
    })

    // ============================================
    // 5. OUTPUT FORMAT
    // ============================================
    describe('Output Format', () => {
        it('should return all required fields', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 1,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Eletrônicos'
            }

            const result = engine.generateInstallments(input)
            const installment = result[0]

            expect(installment).toHaveProperty('installmentNumber')
            expect(installment).toHaveProperty('totalInstallments')
            expect(installment).toHaveProperty('amount')
            expect(installment).toHaveProperty('dueDate')
            expect(installment).toHaveProperty('description')
            expect(installment).toHaveProperty('category')
            expect(installment).toHaveProperty('status')
            expect(installment).toHaveProperty('paymentMethod')
        })

        it('should return valid ISO date strings', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 1,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            // Should be YYYY-MM-DD format
            expect(result[0].dueDate).toMatch(/^\d{4}-\d{2}-\d{2}$/)
        })

        it('should default status to pending', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 1,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result[0].status).toBe('pending')
        })
    })

    // ============================================
    // 6. EDGE CASES
    // ============================================
    describe('Edge Cases', () => {
        it('should handle single installment (no installments)', () => {
            const input: InstallmentInput = {
                totalAmount: 100,
                numberOfInstallments: 1,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Pagamento à vista',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result).toHaveLength(1)
            expect(result[0].amount).toBe(100)
            expect(result[0].description).toBe('Parcela 1/1 - Pagamento à vista')
        })

        it('should handle very large number of installments', () => {
            const input: InstallmentInput = {
                totalAmount: 2400,
                numberOfInstallments: 24,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Financiamento',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            expect(result).toHaveLength(24)
            expect(result[23].installmentNumber).toBe(24)
            // Last installment should be in January 2027
            expect(result[23].dueDate).toBe('2026-12-15')
        })

        it('should handle very small amounts', () => {
            const input: InstallmentInput = {
                totalAmount: 1.5,
                numberOfInstallments: 3,
                startDate: new Date('2025-01-15'),
                paymentMethod: 'boleto',
                description: 'Produto barato',
                category: 'Outros'
            }

            const result = engine.generateInstallments(input)

            const total = result.reduce((sum, i) => sum + i.amount, 0)
            expect(total).toBeCloseTo(1.5, 2)
        })
    })
})
