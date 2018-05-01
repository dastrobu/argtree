/** create a simple ascii table */
internal func createTable(_ rows: [[String]]) -> String {
    var colMaxCount: [Int] = []
    // determine the widths of the columns
    rows.forEach { row in
        row.enumerated().forEach { i, col in
            if colMaxCount.count <= i {
                colMaxCount.append(col.count)
            }
            colMaxCount[i] = max(colMaxCount[i], col.count)
        }
    }

    // set the last col count to zero, to avoid padding the last col
    if colMaxCount.popLast() != nil {
        colMaxCount.append(0)
    }

    // format the columns
    let r = rows.map { row in
        return row
            .enumerated()
            .map({ i, col in
                if col.count < colMaxCount[i] {
                    // right pad texts with whitespace
                    return col + String(repeating: " ", count: colMaxCount[i] - col.count)
                }
                return col
            }).joined(separator: " ")
    }
    return r.joined(separator: "\n")
}

/**
 * Flag to show a help text
 */
public class Help: Flag {

    init(longName: String? = "help",
         shortName: Character? = "h",
         description: String? = "print this help",
         longPrefix: String = "--",
         shortPrefix: String = "-",
         parsed: OnParsed?) {
        super.init(longName: longName, shortName: shortName, description: description, parsed: parsed)
    }
}
