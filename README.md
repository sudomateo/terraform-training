# Terraform Training

This material is for those that want to learn HashiCorp
[Terraform](https://terraform.io) and better understand the language and its
internals.

## Instructors

### Matthew Sanabria

_Matthew Sanabria is a Senior Software Engineer at HashiCorp and a former
Adjunct Instructor at New Jersey Institute of Technology (NJIT). At HashiCorp,
Matthew develops the Terraform Enterprise product and mentors other engineers.
At NJIT, he designed and taught a new curriculum for the IT340 Introduction to
System Administration course. With over 7 years of professional teaching
experience, Matthew enjoys mentoring others and contributing back to the
community._

Twitter: [@sudomateo](https://twitter.com/sudomateo)

## Recommended Experience

This material is designed to be taught in an instructor-led classroom
environment. While you'll find most of the content and code already present in
the material, there are contextual concepts that the instructor is meant to
cover in class.

While this material assumes no prior experience with Terraform, students with
the following background will get the most out of the class:

- Experience provisioning and managing infrastructure such as virtual machines,
  databases, firewall rules, etc.
- Familiar with programming concepts such as conditionals, arrays, hash maps,
  and functions.
- Comfortable using and maneuvering around the command line interface (CLI).

## Preparing for Class

You can prepare for class by performing the following tasks. We will cover
these in class for those that have not already completed it.

### Install Terraform

Download and install Terraform from https://www.terraform.io/downloads.

Ensure the `terraform` (macOS and Linux) or `terraform.exe` (Windows) binary is
on your `PATH`.

#### Install Graphviz

Terraform can generate a graph of its resources. To visualize this graph,
install [Graphviz](https://graphviz.org/). While not a requirement to use
Terraform, it helps make use of features provided by `terraform graph`.
