/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    roots: ['<rootDir>/src'],
    testMatch: ['**/__tests__/**/*.test.ts'],
    moduleNameMapper: {
        '^@/(.*)$': '<rootDir>/src/$1'
    },
    transform: {
        '^.+\\.tsx?$': ['ts-jest', {
            tsconfig: {
                module: 'CommonJS',
                moduleResolution: 'node',
                esModuleInterop: true,
                allowSyntheticDefaultImports: true
            }
        }]
    },
    collectCoverageFrom: [
        'src/lib/**/*.ts',
        '!src/lib/**/*.test.ts'
    ]
}
