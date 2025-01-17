/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  project_roles = [
    "roles/owner"
  ]

  organization_roles = [
    "roles/orgpolicy.policyAdmin"
  ]
}

resource "google_service_account" "int_test" {
  project      = module.project.project_id
  account_id   = "ci-account"
  display_name = "ci-account"
}

resource "google_project_iam_member" "int_test_project" {
  for_each = toset(local.project_roles)

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.int_test.email}"
}

resource "google_project_iam_member" "int_test_project_exclude" {
  for_each = toset(local.project_roles)

  project = module.project_exclude.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.int_test.email}"
}

resource "google_organization_iam_member" "int_test" {
  for_each = toset(local.organization_roles)

  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.int_test.email}"
}

resource "google_service_account_key" "int_test" {
  service_account_id = google_service_account.int_test.id
}

resource "null_resource" "wait_permissions" {
  # Adding a pause as a workaround for of the provider issue
  # https://github.com/terraform-providers/terraform-provider-google/issues/1131
  provisioner "local-exec" {
    command = "echo sleep 30s for permissions to get granted; sleep 30"
  }
  depends_on = [
    google_organization_iam_member.int_test,
    google_project_iam_member.int_test_project,
    google_project_iam_member.int_test_project_exclude
  ]
}
