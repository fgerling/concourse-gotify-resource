# concourse-gotify-resource
![CI-Test](https://concourse-ci.17xf.de/api/v1/teams/main/pipelines/concourse-gotify-resource/jobs/test/badge)

A Concourse Resource for sending notifications to [Gotify](https://gotify.net/).

Inspired by [michaellihs/rocketchat-notification-resource](https://github.com/michaellihs/rocketchat-notification-resource).

## Resource Usage
Only `out` is implemented in a useful way.

### Sample Pipeline
Here is a sample usage of the Gotify notification resource

```
 ---
 resource_types:
   - name: gotify-resource
     type: registry-image
     source:
       tag: latest
       repository: fgerling/gotify-resource

 resources:
   - name: gotify-pusher
     type: gotify-resource
     source:
       url: ((gotify.url))
       appToken: ((gotify.app_token))
jobs:
  - put: gotify-pusher
    params:
      message: Test message
      title: Test title
      priority: 5
```

### Resource Configuration

#### The `resources.type:gotify-resource.source` Section

| Parameter  | Type   | Required | Default     | Description                                                       |
|:-----------|:-------|:---------|:------------|:------------------------------------------------------------------|
| `url`      | URL    | yes      |             | URL of the Gotify server to send notifications to                 |
| `appToken` | String | yes      |             | App Token with which Concourse authenticates at Gotify            |

#### The `jobs.put.params` Section

| Parameter | Type   | Required | Default     | Description                                                        |
|:----------|:-------|:---------|:------------|:-------------------------------------------------------------------|
| `title`   | String | no       |             | The title of the notification                                      |
| `message` | String | no       |             | The message of the notification                                    |
| `priority`| Number | no       |             | The priority of the notification                                   |


## Developer's Guide
### Test
```
# alias docker=podman
docker build -t fgerling/gotify-resource:test -f ./Dockerfile.test .
docker run -ti --rm  --volume $(pwd):/repo fgerling/gotify-resource:test bash /app/test.sh /repo/assets
```

