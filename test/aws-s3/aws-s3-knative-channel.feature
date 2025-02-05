@knative
Feature: AWS S3 Kamelet - binding to Knative channel

  Background:
    Given variables
      | aws.s3.bucketNameOrArn | mybucket |
      | aws.s3.message | Hello from S3 Kamelet |
      | aws.s3.key | hello.txt |

  Scenario: Create infrastructure
    # Start LocalStack container
    Given Enable service S3
    Given start LocalStack container
    # Create AWS-S3 client
    Given New global Camel context
    Given load to Camel registry amazonS3Client.groovy
    # Create Knative broker and channel
    Given create Knative broker default
    And Knative broker default is running
    And create Knative channel messages

  Scenario: Verify AWS-S3 Kamelet to InMemoryChannel binding
    # Create binding
    Given load KameletBinding aws-s3-to-knative-channel.yaml
    Given load KameletBinding knative-channel-to-log.yaml
    Then KameletBinding aws-s3-to-knative-channel should be available
    And KameletBinding knative-channel-to-log should be available
    And Camel K integration aws-s3-to-knative-channel is running
    And Camel K integration knative-channel-to-log is running
    And Camel K integration aws-s3-to-knative-channel should print Started aws-s3-to-knative-channel
    And Camel K integration knative-channel-to-log should print Installed features
    Then sleep 10000 ms
    # Verify Kamelet source
    Given Camel exchange message header CamelAwsS3Key="${aws.s3.key}"
    Given send Camel exchange to("aws2-s3://${aws.s3.bucketNameOrArn}?amazonS3Client=#amazonS3Client") with body: ${aws.s3.message}
    Then Camel K integration knative-channel-to-log should print ${aws.s3.message}

  Scenario: Remove resources
    # Remove Camel K resources
    Given delete KameletBinding aws-s3-to-knative-channel
    Given delete KameletBinding knative-channel-to-log
    # Remove Knative resources
    Given delete Knative broker default
    Given delete Knative channel messages
    # Stop LocalStack container
    Given stop LocalStack container
