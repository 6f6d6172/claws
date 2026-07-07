module Claws
  module Rule
    class StaticAwsCredentials < BaseRule
      description <<~DESC
        Avoid using static AWS credentials where possible. Static AWS credentials
        encourages bad practices like overly broad permissions and credential reuse.
        Additionally, if AWS credentials are accidentally leaked, they may be difficult
        to rotate and tricky to audit.

        Instead, use OIDC to generate AWS credentials. This generates short-lived
        credentials which can help mitigate damage from a potential leak and encourages
        good practices like tightly-scoped permissions and secrets hygiene.

        For more information:
        https://github.com/betterment/claws/blob/main/README.md#staticawscredentials
      DESC

      # right now this will flag anything that uses aws credentials
      # how can we scope it to unsafe behaviors?
      on_step %(
        $step.meta.action.name == "aws-actions/configure-aws-credentials"
      ), highlight: "with"
    end
  end
end
