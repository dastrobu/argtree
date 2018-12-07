/**
 * Flag to show a help text
 */
public class Help: Flag {

    /** create a simple ascii table */
    public static func createTable(_ rows: [[String]]) -> String {
        var colCount = 0
        var colWidths: [Int] = []
        // number of lines per row
        var rowLines: [Int] = Array(repeating: 0, count: rows.count)
        // determine the widths of the columns
        rows.enumerated().forEach { i, cols in
            colCount = max(colCount, cols.count)
            cols.enumerated().forEach { j, col in
                let lines = String(col).split(separator: "\n")
                rowLines[i] = max(rowLines[i], lines.count)
                let colCount = lines.map {
                    $0.count
                }.max() ?? 0
                if colWidths.count <= j {
                    colWidths.append(colCount)
                }
                colWidths[j] = max(colWidths[j], col.count)
            }
        }

        // set the last col count to zero, to avoid padding the last col
        if colWidths.popLast() != nil {
            colWidths.append(0)
        }

        // compute rows that account for multiline rows
        var adjustedRows: [[String]] = []
        for i in 0..<rows.count {
            for _ in 0..<rowLines[i] {
                adjustedRows.append(Array(repeating: "", count: colCount))
            }
        }

        var i = 0
        rows.enumerated().forEach { j, cols in
            cols.enumerated().forEach { l, col in
                let lines = String(col).split(separator: "\n")
                lines.enumerated().forEach { k, line in
                    adjustedRows[i + k][l] = String(line)
                }
            }
            i += rowLines[j]
        }

        // format the columns
        let r = adjustedRows.map { row in
            return row
                .enumerated()
                .map({ i, col in
                    if col.count < colWidths[i] {
                        // right pad texts with whitespace
                        return col + String(repeating: " ", count: colWidths[i] - col.count)
                    }
                    return col
                }).joined(separator: " ")
        }
        return r.joined(separator: "\n")
    }

    public init(longName: String? = "help",
                shortName: Character? = "h",
                description: String? = "print this help",
                longPrefix: String = "--",
                shortPrefix: String = "-",
                parsed: OnParsed?) {
        super.init(longName: longName, shortName: shortName, description: description, parsed: parsed)
    }
}
