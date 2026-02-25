import Foundation

let jsonString = """
{"type": "expense", "amount": 500, "description": "Salário", "category": "Salário"}
"""
do {
    let jsonData = jsonString.data(using: .utf8)!
    let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    if let amount = dict?["amount"] as? Double {
        print("Double cast SUCCESS: \(amount)")
    } else {
        print("Double cast FAILED")
        if let num = dict?["amount"] as? NSNumber {
            print("NSNumber cast SUCCESS: \(num.doubleValue)")
        }
    }
} catch {
    print("Error: \(error)")
}
