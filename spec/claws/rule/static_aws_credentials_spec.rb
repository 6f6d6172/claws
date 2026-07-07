RSpec.describe Claws::Rule::StaticAwsCredentials do
  before do
    load_detection
  end

  context "with the official configure-aws-credentials action" do
    it "flags static aws credentials" do
      violations = analyze(<<~YAML)
        name: Push File to S3

        on:
          push:
            branches: [ "main" ]

        jobs:
          push-relations:
            name: Push File to S3
            runs-on: ubuntu-latest
            steps:
              - name: Configure prod aws credentials
                uses: aws-actions/configure-aws-credentials@b47578312673ae6fa5b5096b330d9fbac3d116df
                with:
                  aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
                  aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                  role-to-assume: arn:aws:iam::1234:role/the-role-that-lets-us-use-s3
                  aws-region: ${{ env.AWS_REGION }}

              - name: Push file to S3
                run: aws s3 cp data.json s3://production-data/
      YAML

      expect(violations.count).to eq(1)
      expect(violations[0].line).to eq(13)
      expect(violations[0].name).to eq("StaticAwsCredentials")
    end

    it "does not flag when oidc is used" do
      violations = analyze(<<~YAML)
        name: Push File to S3

        on:
          push:
            branches: [ "main" ]

        jobs:
          push-relations:
            name: Push File to S3
            runs-on: ubuntu-latest
            steps:
              - name: Configure prod aws credentials
                uses: aws-actions/configure-aws-credentials@b47578312673ae6fa5b5096b330d9fbac3d116df
                with:
                  role-to-assume: arn:aws:iam::1234:role/the-role-that-lets-us-use-s3
                  aws-region: ${{ env.AWS_REGION }}

              - name: Push file to S3
                run: aws s3 cp data.json s3://production-data/
      YAML

      expect(violations.count).to eq(0)
    end

    it "does not flag when credentials are likely to be non-static" do
      violations = analyze(<<~YAML)
        name: Push File to S3

        on:
          push:
            branches: [ "main" ]

        jobs:
          push-relations:
            name: Push File to S3
            runs-on: ubuntu-latest
            steps:
              - name: Configure AWS Credentials 1
                id: creds
                uses: aws-actions/configure-aws-credentials@b47578312673ae6fa5b5096b330d9fbac3d116df
                with:
                  aws-region: us-east-2
                  role-to-assume: arn:aws:iam::123456789100:role/my-github-actions-role
                  output-credentials: true
              - name: Configure AWS Credentials 2
                uses: aws-actions/configure-aws-credentials@b47578312673ae6fa5b5096b330d9fbac3d116df
                with:
                  aws-region: us-east-2
                  aws-access-key-id: ${{ steps.creds.outputs.aws-access-key-id }}
                  aws-secret-access-key: ${{ steps.creds.outputs.aws-secret-access-key }}
                  aws-session-token: ${{ steps.creds.outputs.aws-session-token }}
                  role-to-assume: arn:aws:iam::123456789100:role/my-other-github-actions-role
              - name: Push file to S3
                run: aws s3 cp data.json s3://production-data/
      YAML

      expect(violations.count).to eq(0)
    end
  end
end
