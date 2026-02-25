import Foundation

let jsonString = """
{"type": "expense", "amount": 500, "description": "Salário", "category": "Salário"}
"""
do {
    let jsonData = jsonString.data(using: .utf8)!
    let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    let amount = dict?["amount"] as? Double
    print("Amount is \(String(describing: amount))")
} catch {
    print("Error: \(error)")
}
