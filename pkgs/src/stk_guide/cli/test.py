import click
from stk_guide.cli import cli


@cli.command("test", short_help="Test")
@click.pass_context
def test(ctx):
    print(1)
