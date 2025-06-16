# This script tries to gather all addons hosts on addons.mozilla.org. 
# The main entry point is the /addons/search endpoint which will return a paginated set of 30k addons at most. This is
# already quite good but as we can see in the response body the whole count is over 500k addons. Though about 420k addons
# have 0 daily users. We won't care about these.
# The strategy is as follows:
# - query the 30k most popular addons
# - then make paginated requests from user count = 1 to the user count of least popular of the most popular 30k
# Though the amount of addons that have 1 daily user is more than 30k, so we can't query all of them. That's okay as we
# are sorting by weekly downloads. So anyone just needs to download the addon and it will be found by the script. 
def main [ 
    addons_yaml: path 
    --sleep-between-calls (-s): duration = 0sec
    --api-base-url (-u): string = "https://addons.mozilla.org/api/v5"
    --job-count (-j): int = 6
    --just-cleanup
] {
    if (not $just_cleanup) {

        # in any case, get the 30k most popular addons
        save-all-addons -p {sort: "users"}
        
        # Then get the users count of the last addon 30k most popular addons and check its daily users count
        let max_users = api "/addons/search" {sort: "users", page_size: 50, page: 600, lang: "en-US"}
            | get results
            | last
            | get average_daily_users

        # for each user count make paginated requests
        $max_users..1 | each {save-all-addons -p {sort: "downloads,updated", users: $in}}
    }

    # after each operation clean up the file
    open $addons_yaml
        | each {from json}
        | reverse
        | uniq-by g
        | sort-by g
        | each {to json --raw}
        | to yaml
        | save $addons_yaml --force
    return


    # Functions

    def get-known-addons [] {
        if ($addons_yaml | path exists) {
            ^cat $addons_yaml | from yaml
        } else {
            "[]" | save $addons_yaml
            return []
        } 
    }

    # function to call the api
    def api [ route: string params = {}] {
        let query  = "?" + ($params | url build-query)
        sleep $sleep_between_calls
        let full_query = $api_base_url + $route + $query;
        
        if (($full_query | str length) > 256) {
            print ("GET " 
                + ($full_query | str substring ..128) 
                + "..." 
                + ($full_query | str substring (-128..))
                + $" \(($full_query | str length) characters long\)"
            )
        } else {
            print ("GET " + $full_query)
        }
        
        http get $full_query
    }

    def get-addon [id: int = -1 --prefetched (-d): table] {
        $prefetched
            | if ($in == null) {api $"/addons/addon/($id)" {lang: "en-US"}} else {$in}
            | {
                g: $in.guid,
                s: $in.slug,
                v: $in.current_version.version,
                u: $in.current_version.file.url,
                h: $in.current_version.file.hash,
                p: ($in.current_version.file.permissions | default []),
                l: ($in.current_version | default {slug: "all-rights-reserved"} license | get license.slug),
            }
    }


    def save-all-addons [--additional-params (-p): record = {}] {
        let first_page = get-addons-page
        let last_job_set = $first_page.page_count // $job_count - 1
        # loop over each job set
        1..($last_job_set + 1)
            | each {|job_set|
                # if we are in the special last job set, we will do the rest 
                let $current_job_count = if ($job_set > $last_job_set) {$first_page.page_count mod $job_count} else {$job_count}
                # spawn $job_count jobs
                0..($current_job_count - 1)
                    | each {|offset|
                        let page = $job_set * $job_count + $offset
                        job spawn {
                            save-addons-from-page $page --prefetched (if $page == 1 {$first_page} else {null})
                        }
                    }
                # wait for all jobs to be finished
                while ((job list | length) > 0) {sleep 50ms}
            }
    
        def get-addons-page [page: int = 1] {
            api "/addons/search/" ({
                sort: "created" # newest first
                page_size: 50, # max page size
                page: $page, # current page
                lang: "en-US", # for performance
            } | merge $additional_params)
        }

        def save-addons-from-page [page: int --prefetched: table] {
            $prefetched 
                | if ($in == null) {get-addons-page $page} else {$in}
                | get results
                | each {get-addon $in.id --prefetched $in}
                | each {to json --raw}
                | to yaml
                | save $addons_yaml --append
        }
    }
}