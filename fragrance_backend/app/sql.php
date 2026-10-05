<?php
/**
 * Splits a .sql file into single statements so the installer can run them one by one.
 * Understands quoted text (so a ";" inside a description does not end a statement)
 * and skips "-- comment" lines.
 */
declare(strict_types=1);

function split_sql(string $sql): array
{
    $statements = [];
    $current = '';
    $length = strlen($sql);
    $quote = null;                       // the quote character we are inside, if any

    for ($i = 0; $i < $length; $i++) {
        $char = $sql[$i];

        if ($quote !== null) {
            $current .= $char;
            if ($char === '\\' && $i + 1 < $length) {       // escaped character, keep both
                $current .= $sql[++$i];
            } elseif ($char === $quote) {
                if ($i + 1 < $length && $sql[$i + 1] === $quote) {   // doubled quote ''
                    $current .= $sql[++$i];
                } else {
                    $quote = null;
                }
            }
            continue;
        }

        if ($char === '-' && substr($sql, $i, 3) === '-- ' || $char === '#') {
            $end = strpos($sql, "\n", $i);                   // comment: skip to end of line
            $i = $end === false ? $length : $end;
            $current .= "\n";
            continue;
        }
        if ($char === "'" || $char === '"' || $char === '`') {
            $quote = $char;
            $current .= $char;
            continue;
        }
        if ($char === ';') {
            if (trim($current) !== '') {
                $statements[] = trim($current);
            }
            $current = '';
            continue;
        }
        $current .= $char;
    }
    if (trim($current) !== '') {
        $statements[] = trim($current);
    }
    return $statements;
}

/** Run every statement of a .sql file. */
function run_sql_file(PDO $pdo, string $file): int
{
    $statements = split_sql((string) file_get_contents($file));
    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }
    return count($statements);
}
