def main [ query: string ] {
    http get $"https://addons.mozilla.org/api/v5/addons/search?({q: $query, page_size: 10, lang: "en-US"} | url build-query)"
        | get results
        | each {{
            name: $in.name.en-US,
            slug: $in.slug
            guid: $in.guid
        }}
}