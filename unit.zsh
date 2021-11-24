function unit {
        local unit_path="/home/mh/scripts/unit/unit-$1"
        $unit_path $flag || echo ERR: No unit $1
}
