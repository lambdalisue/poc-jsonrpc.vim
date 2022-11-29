const l = Deno.listen({ hostname: "127.0.0.1", port: 8080 });
console.log("listen");
for await (const c of l) {
  console.log("connect");
  await c.write(
    new TextEncoder().encode(
      `{"jsonrpc": "2.0", "method": "execute", "params": ["echomsg 'Hello world'", ""]}\n`,
    ),
  );
}
