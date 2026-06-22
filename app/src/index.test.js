const request = require('supertest');
const app = require('./index');

describe('API Endpoints', () => {
  it('GET / should return hello message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('message');
    expect(res.body.message).toContain('Hello from the AWS CI/CD Pipeline App!');
  });

  it('GET /health should return OK', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.text).toEqual('OK');
  });
});
