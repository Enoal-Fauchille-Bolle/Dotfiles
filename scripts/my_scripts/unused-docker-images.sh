docker images -f "dangling=true" --format "{{.Size}}" | awk '
function to_bytes(size) {
    unit = substr(size, length(size)-1, 2)
    size_value = substr(size, 1, length(size) - 2)
    if (unit == "GB") return size_value * 1024 * 1024 * 1024;
    if (unit == "MB") return size_value * 1024 * 1024;
    if (unit == "KB") return size_value * 1024;
    return size_value;
}
{
    sum += to_bytes($1)
}
END {
    total_go = sum / (1024 * 1024 * 1024)
    printf "%.2f GB\n", total_go
}'
