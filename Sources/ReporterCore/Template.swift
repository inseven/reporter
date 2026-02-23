// Copyright (c) 2024-2026 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import BinaryCodable
import Crypto
import Stencil
import SwiftSMTP

public class Template {

    static let text = """
{% for item in report.folders %}{% if item.changes.changes.count > 0 %}
{{ item.name }} ({{ item.path }}) - {% if item.changes.changes.count > 1 %}{{ item.changes.changes.count }} changes{% else %}1 change{% endif %}

{% for change in item.changes.changes -%}
{% if change.isAddition -%}
+ {{ change.source.path }}
{% elif change.isModification -%}
~ {{ change.source.path }}
{% else -%}
- {{ change.source.path }}
{% endif -%}
{% endfor -%}

{% endif %}{% endfor %}
"""

    static let html = """
<html>
    <head>
        <meta name="color-scheme" content="light dark">
        <style type="text/css">

            :root {
                --primary-background-color: #fff;
                --primary-foreground-color: #000;
                --secondary-background-color: #f6f8fa;
                --addition-background-color: #dafbe1;
                --deletion-background-color: #ffebe9;
                --modification-background-color: #c7abff;
                --border-color: #d1d9e0;
                --padding: 0.5rem;
            }

            @media (prefers-color-scheme: dark) {
                :root {
                    --primary-background-color: #181818;
                    --primary-foreground-color: #fff;
                    --secondary-background-color: #151b23;
                    --addition-background-color: #2ea04326;
                    --deletion-background-color: #f851491a;
                    --modification-background-color: #260960;
                    --border-color: #3d444d;
                }
            }

            body {
                background-color: var(--primary-background-color);
                color: var(--primary-foreground-color);
            }

            hr {
                border: 0;
                border-bottom: 1px solid var(--border-color);
            }

            footer {
                color: #aaa;
                text-align: center;
            }

            .folder {
                border: 1px solid var(--border-color);
                border-radius: 8px;
                margin-bottom: 1rem;
                overflow: hidden;
            }

            .folder header {
                background-color: var(--secondary-background-color);
                padding: calc(2 * var(--padding));
            }

            .folder header .name {
                font-weight: bold;
            }

            ul.changes {
                list-style: none;
                margin: 0;
                padding: 0;
                border-top: 1px solid var(--border-color);
            }

            ul.changes li {
                display: block;
                padding: var(--padding) calc(2 * var(--padding));
            }

            .addition {
                background-color: var(--addition-background-color);
            }

            .deletion {
                background-color: var(--deletion-background-color);
            }

            .modification {
                background-color: var(--modification-background-color);
            }

        </style>
    </head>
    <body>
        {% for item in report.folders %}{% if item.changes.changes.count > 1 %}
            <section class="folder">
                <header>
                    <div class="name">{{ item.name }}</div>
                </header>
                {% if item.changes.isEmpty %}{% else %}
                    <ul class="changes">
                        {% for change in item.changes.changes %}
                            {% if change.isAddition %}
                                <li class="addition">{{ change.source.path }}</li>
                            {% elif change.isModification %}
                                <li class="modification">{{ change.source.path }}</li>
                            {% else %}
                                <li class="deletion">{{ change.source.path }}</li>
                            {% endif %}
                        {% endfor %}
                    </ul>
                {% endif %}
            </section>
        {% endif %}{% endfor %}

        <footer>
            <p>
                Generated with <a href="https://github.com/inseven/reporter">Reporter</a> by <a href="https://jbmorley.co.uk">Jason Morley</a>.
            </p>
        </footer>

    </body>
</html>
"""

}
